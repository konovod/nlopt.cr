require "./nlopt"

module NLopt
  extend self
  private DEFAULT_CONSTRAINT_TOL = 1e-8

  alias ConstraintFunction = Proc(Slice(Float64), Slice(Float64)?, Float64)

  def self.equality(tol, f)
    SingleConstraint.new(tol, f, equality: true)
  end

  def self.inequality(tol, f)
    SingleConstraint.new(tol, f, equality: false)
  end

  def self.equality(f)
    SingleConstraint.new(true, DEFAULT_CONSTRAINT_TOL, f)
  end

  def self.inequality(f)
    SingleConstraint.new(false, DEFAULT_CONSTRAINT_TOL, f)
  end

  def self.equality(tol = DEFAULT_CONSTRAINT_TOL, &block : (Slice(Float64), Slice(Float64)? -> Float64))
    SingleConstraint.new(true, tol, ->(x : Slice(Float64), grad : Slice(Float64)?) { block.call(x, grad) })
  end

  def self.inequality(tol = DEFAULT_CONSTRAINT_TOL, &block : (Slice(Float64), Slice(Float64)? -> Float64))
    SingleConstraint.new(false, tol, ->(x : Slice(Float64), grad : Slice(Float64)?) { block.call(x, grad) })
  end

  class SingleConstraint < Constraint
    property f : ConstraintFunction
    property tol : Float64
    property equality : Bool

    protected def eval_f(n, x : Float64*, grad : Float64*) : Float64
      need_grad = grad != Pointer(Float64).new(0)
      f.call(x.to_slice(n), need_grad ? grad.to_slice(n) : nil)
    end

    protected def initialize(@equality, @tol, @f)
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
