module NLopt
  enum Direction
    Minimize =  1
    Maximize = -1
  end

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
  alias ObjectiveGradOnly = Proc(Slice(Float64), Slice(Float64), Void)

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
        @max > 0 ? 0.0 : @max*2
      elsif @max.infinite?
        @min < 0 ? 0.0 : @min*2
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

  class Solver
    @handle : LibNLopt::Opt?
    getter variables
    property objective : ObjectiveWithGrad | ObjectiveNoGrad | Nil
    property obj_gradient : ObjectiveGradOnly | Nil
    property optim_dir = Direction::Minimize

    def initialize(algorithm, size)
      @handle = LibNLopt.create(algorithm, size)
      @variables = Array(Variable).new(size) { Variable.new }
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

    protected def initialize(@handle, @objective, @obj_gradient, @optim_dir, vars)
      @variables = Array(Variable).new(vars.size) { |i| vars[i].dup }
    end

    def clone
      Solver.new(@handle.try { |h| LibNLopt.copy(h) }, @objective, @obj_gradient, @optim_dir, @variables)
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

    private def set_objective
      f = ->(n : LibC::UInt, x : LibC::Double*, grad : LibC::Double*, data : Void*) {
        it = data.as(Solver)
        it.eval_obj(n, x, grad)
      }
      case @optim_dir
      when Direction::Minimize
        LibNLopt.set_min_objective(@handle.not_nil!, f, self.as(Void*))
      else
        LibNLopt.set_max_objective(@handle.not_nil!, f, self.as(Void*))
      end
    end

    private def set_vars
      arr = Slice(Float64).new(dimension, 0.0)
      @variables.each_with_index { |v, i| arr[i] = v.min }
      LibNLopt.set_lower_bounds(@handle.not_nil!, arr)
      @variables.each_with_index { |v, i| arr[i] = v.max }
      LibNLopt.set_upper_bounds(@handle.not_nil!, arr)

      if @variables.any? { |v| v.initial_step.nil? }
        guess = Slice(Float64).new(dimension) { |i| @variables[i].guess || @variables[i].default_guess }
        LibNLopt.get_initial_step(@handle.not_nil!, guess, arr)
      end
      @variables.each_with_index do |v, i|
        if step = v.initial_step
          arr[i] = step
        end
      end
      LibNLopt.set_initial_step(@handle.not_nil!, arr)
      @variables.each_with_index { |v, i| arr[i] = v.abs_tol || -1.0 }
      LibNLopt.set_xtol_abs(@handle.not_nil!, arr)
    end

    def solve
      set_objective
      set_vars
      x = Array(Float64).new(dimension) { |i| @variables[i].guess || @variables[i].default_guess }
      result = LibNLopt.optimize(@handle.not_nil!, x, out f)
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
