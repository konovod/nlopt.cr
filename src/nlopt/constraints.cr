require "./nlopt"

module NLopt
  # fun add_equality_constraint = nlopt_add_equality_constraint(opt : Opt,
  # h : Func, h_data : Void*, tol : LibC::Double) : Result
  alias ConstraintFunction = Proc(Slice(Float64), Slice(Float64)?, Float64)

  class SingleConstraint < Constraint
    property f : ConstraintFunction
    property tol : Float64
    property equality : Bool

    protected def eval_f(n, x : Float64*, grad : Float64*) : Float64
      need_grad = grad != Pointer(Float64).new(0)
      f.call(x.to_slice(n), need_grad ? grad.to_slice(n) : nil)
    end

    def initialize(@tol, *, @equality = false, &block : (Slice(Float64), Slice(Float64)? -> Float64))
      @f = ->(x : Slice(Float64), grad : Slice(Float64)?) do
        block.call(x, grad)
      end
    end

    def apply(h : LibNLopt::Opt)
      callback = ->(n : LibC::UInt, x : LibC::Double*, grad : LibC::Double*, data : Void*) {
        it = data.as(SingleConstraint)
        it.eval_f(n, x, grad)
      }
      if @equality
        LibNLopt.add_equality_constraint(h, callback, self.as(Void*), tol)
      else
        LibNLopt.add_inequality_constraint(h, callback, self.as(Void*), tol)
      end
    end
  end
end
