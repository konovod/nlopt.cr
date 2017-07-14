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

  class Solver
    @handle : LibNLopt::Opt?
    property objective : ObjectiveWithGrad | ObjectiveNoGrad | Nil
    property obj_gradient : ObjectiveGradOnly | Nil
    property optim_dir = Direction::Minimize

    def initialize(algorithm, size)
      @handle = LibNLopt.create(algorithm, size)
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

    protected def initialize(@handle, @objective, @obj_gradient, @optim_dir)
    end

    def clone
      Solver.new(@handle.try { |h| LibNLopt.copy(h) }, @objective, @obj_gradient, @optim_dir)
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

    def solve
      set_objective
      x = Array(Float64).new(dimension, 0.0)
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
  end
end
