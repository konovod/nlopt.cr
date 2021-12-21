require "./libnlopt"

module NLopt
  enum Direction
    Minimize =  1
    Maximize = -1
  end
  private DEFAULT_XTOL_REL = 1e-9

  enum Algorithm
    def to_s
      String.new(LibNLopt.algorithm_name(self))
    end
  end

  def self.srand(seed : UInt64? = nil)
    if seed
      LibNLopt.srand(seed)
    else
      LibNLopt.srand_time
    end
  end

  alias ObjectiveWithGrad = Proc(Slice(Float64), Slice(Float64)?, Float64)
  alias ObjectiveNoGrad = Proc(Slice(Float64), Float64)
  alias ObjectiveGradOnly = Proc(Slice(Float64), Slice(Float64), Nil)
  alias ObjectivePrecondition = Proc(Slice(Float64), Slice(Float64), Nil)
  alias ObjectivePreconditionEval = Proc(Slice(Float64), Slice(Float64), Slice(Float64), Nil)

  class Variable
    property min : Float64
    property max : Float64
    property guess : Float64?
    property abs_tol : Float64?
    property initial_step : Float64?

    def default_guess
      if @min.infinite? && @max.infinite?
        0.0
      elsif @min.infinite?
        @max > 0 ? 0.0 : {@max*2, -1.0}.min
      elsif @max.infinite?
        @min < 0 ? 0.0 : {@min*2, 1.0}.max
      else
        (@min + @max) / 2
      end
    end

    def set(*, min = @min, max = @max, guess = @guess, abs_tol = @abs_tol, initial_step = @initial_step)
      @min = min.to_f
      @max = max.to_f
      @guess = guess.try(&.to_f)
      @abs_tol = abs_tol.try(&.to_f)
      @initial_step = initial_step.try(&.to_f)
    end

    protected def initialize(@min = -Float64::INFINITY, @max = Float64::INFINITY, @guess = nil, @abs_tol = nil, @initial_step = nil)
    end
  end

  abstract class Constraint
    abstract def apply(h : LibNLopt::Opt)
  end

  class Solver
    @handle : LibNLopt::Opt?
    getter variables
    property objective : ObjectiveWithGrad | ObjectiveNoGrad | Nil
    property obj_gradient : ObjectiveGradOnly?
    property precondition : ObjectivePrecondition | ObjectivePreconditionEval | Nil
    property optim_dir = Direction::Minimize
    property constraints

    def initialize(algorithm, size)
      @handle = LibNLopt.create(algorithm, size)
      @variables = Array(Variable).new(size) { Variable.new }
      @constraints = [] of Constraint
    end

    def algorithm : Algorithm
      LibNLopt.get_algorithm(@handle.not_nil!)
    end

    def dimension
      Int32.new(LibNLopt.get_dimension(@handle.not_nil!))
    end

    def free
      if @handle
        LibNLopt.destroy(@handle.not_nil!)
        @handle = nil
      end
    end

    def finalize
      free
    end

    protected def initialize(@handle, @objective, @obj_gradient, @optim_dir, vars, cons)
      @variables = Array(Variable).new(vars.size) { |i| vars[i].dup }
      @constraints = Array(Constraint).new(cons.size) { |i| cons[i].dup }
    end

    def clone
      Solver.new(@handle.try { |h| LibNLopt.copy(h) }, @objective, @obj_gradient, @optim_dir, @variables, @constraints)
    end

    protected def eval_obj(n, x : Float64*, grad : Float64*) : Float64
      need_grad = grad != Pointer(Float64).new(0)
      case obj = @objective
      when ObjectiveWithGrad
        obj.call(x.to_slice(n), need_grad ? grad.to_slice(n) : nil)
      when ObjectiveNoGrad
        f = obj.call(x.to_slice(n))
        if need_grad
          @obj_gradient.not_nil!.call(x.to_slice(n), grad.to_slice(n))
        end
        f
      else
        raise "incorrect objective"
      end
    end

    # alias ObjectivePrecondition = Proc(Slice(Float64), Slice(Float64), Nil)
    # alias ObjectivePreconditionEval = Proc(Slice(Float64), Slice(Float64), Slice(Float64), Nil)
    @hessian : Array(Float64)?

    protected def eval_pre(n, x : Float64*, v : Float64*, vpre : Float64*)
      case pre = @precondition
      when ObjectivePrecondition
        h = @hessian
        unless h
          h = Array(Float64).new(n*n, 0.0)
          @hessian = h
        end
        pre.call(x.to_slice(n), h.to_unsafe.to_slice(n*n))
        n.times do |i|
          vpre[i] = (0...n).sum { |j| h[i*n + j]*v[j] }
        end
      when ObjectivePreconditionEval
        pre.call(x.to_slice(n), v.to_slice(n), vpre.to_slice(n))
      else
        raise "incorrect precondition"
      end
    end

    private def apply_objective(h)
      f = ->(n : LibC::UInt, x : LibC::Double*, grad : LibC::Double*, data : Void*) {
        it = data.as(Solver)
        it.eval_obj(n, x, grad)
      }
      if @precondition
        f_pre = ->(n : LibC::UInt, x : LibC::Double*, v : Float64*, vpre : Float64*, data : Void*) {
          it = data.as(Solver)
          it.eval_pre(n, x, v, vpre)
        }
        @hessian = nil
        case @optim_dir
        when Direction::Minimize
          LibNLopt.set_precond_min_objective(h, f, f_pre, self.as(Void*))
        else
          LibNLopt.set_precond_max_objective(h, f, f_pre, self.as(Void*))
        end
      else
        case @optim_dir
        when Direction::Minimize
          LibNLopt.set_min_objective(h, f, self.as(Void*))
        else
          LibNLopt.set_max_objective(h, f, self.as(Void*))
        end
      end
    end

    private def apply_vars(h)
      arr = Slice(Float64).new(dimension, 0.0)
      @variables.each_with_index { |v, i| arr[i] = v.min }
      LibNLopt.set_lower_bounds(h, arr)
      @variables.each_with_index { |v, i| arr[i] = v.max }
      LibNLopt.set_upper_bounds(h, arr)

      if @variables.any? { |v| v.initial_step.nil? }
        guess = Slice(Float64).new(dimension) { |i| @variables[i].guess || @variables[i].default_guess }
        LibNLopt.get_initial_step(h, guess, arr)
      end
      @variables.each_with_index do |v, i|
        if step = v.initial_step
          arr[i] = step
        end
      end
      LibNLopt.set_initial_step(h, arr)
      @variables.each_with_index { |v, i| arr[i] = v.abs_tol || -1.0 }
      LibNLopt.set_xtol_abs(h, arr)
      return arr.any?(&.> 0.0)
    end

    private def apply_constraints(h)
      LibNLopt.remove_inequality_constraints(h)
      LibNLopt.remove_equality_constraints(h)
      @constraints.each { |c| c.apply(h) }
    end

    private def has_stop_condition
      ftol_rel > 0 || ftol_abs > 0 || xtol_rel > 0 || maxeval > 0 || maxtime > 0
    end

    def solve
      raise "solver not initialized" unless h = @handle
      apply_objective(h)
      any_stop = apply_vars(h)
      apply_constraints(h)
      unless any_stop || has_stop_condition
        self.xtol_rel = DEFAULT_XTOL_REL
      end
      x = Array(Float64).new(dimension) { |i| @variables[i].guess || @variables[i].default_guess }
      result = LibNLopt.optimize(h, x, out f)
      {result, x, f}
    end

    {% for var in {:stopval, :ftol_rel, :ftol_abs, :xtol_rel, :maxeval, :maxtime, :population, :vector_storage} %}
      def {{var.id}}
        LibNLopt.get_{{var.id}}(@handle.not_nil!)
      end
      def {{var.id}}=(value)
        LibNLopt.set_{{var.id}}(@handle.not_nil!, value)
      end
    {% end %}

    def local_optimizer(local : Solver)
      LibNLopt.set_local_optimizer(@handle.not_nil!, local.@handle.not_nil!)
    end
  end
end
