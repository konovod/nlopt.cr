require "./nlopt"

module NLopt
  extend self
  private DEFAULT_CONSTRAINT_TOL = 1e-8

  alias ConstraintFunction = Proc(Slice(Float64), Slice(Float64)?, Float64)
  alias VectorConstraintFunction = Proc(Slice(Float64), Slice(Float64)?, Slice(Float64), Nil)

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

  def self.equalities(m, tol, f)
    VectorConstraint.new(m, tol, f, equality: true)
  end

  def self.inequalities(m, tol, f)
    VectorConstraint.new(m, tol, f, equality: false)
  end

  def self.equalities(m, f)
    VectorConstraint.new(true, m, DEFAULT_CONSTRAINT_TOL, f)
  end

  def self.inequalities(m, f)
    VectorConstraint.new(false, m, DEFAULT_CONSTRAINT_TOL, f)
  end

  def self.equalities(m, tol = DEFAULT_CONSTRAINT_TOL, &block : (Slice(Float64), Slice(Float64)?, Slice(Float64) -> Nil))
    VectorConstraint.new(true, m, tol, ->(x : Slice(Float64), grad : Slice(Float64)?, result : Slice(Float64)) { block.call(x, grad, result) })
  end

  def self.inequalities(m, tol = DEFAULT_CONSTRAINT_TOL, &block : (Slice(Float64), Slice(Float64)?, Slice(Float64) -> Nil))
    VectorConstraint.new(false, m, tol, ->(x : Slice(Float64), grad : Slice(Float64)?, result : Slice(Float64)) { block.call(x, grad, result) })
  end

  class SingleConstraint < Constraint
    property f : ConstraintFunction
    property tol : Float64
    property equality : Bool

    protected def eval_f(n, x : Float64*, grad : Float64*) : Float64
      need_grad = grad != Pointer(Float64).null
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

  class VectorConstraint < Constraint
    property f : VectorConstraintFunction
    property tol : Array(Float64)
    property equality : Bool
    property m : Int32

    protected def eval_f(n, x : Float64*, grad : Float64*, result : Float64*) : Nil
      need_grad = grad != Pointer(Float64).null
      f.call(x.to_slice(n), need_grad ? grad.to_slice(@m*n) : nil, result.to_slice(m))
    end

    protected def initialize(@equality, @m, tol, @f)
      if tol.is_a? Indexable
        @tol = Array(Float64).new(@m) { |i| tol[i] }
      else
        @tol = Array(Float64).new(@m, tol.to_f)
      end
    end

    def apply(h : LibNLopt::Opt)
      callback = ->(m : LibC::UInt, result : LibC::Double*, n : LibC::UInt, x : LibC::Double*, grad : LibC::Double*, data : Void*) {
        it = data.as(VectorConstraint)
        it.eval_f(n, x, grad, result)
        nil
      }
      if @equality
        LibNLopt.add_equality_mconstraint(h, @m, callback, self.as(Void*), tol)
      else
        LibNLopt.add_inequality_mconstraint(h, @m, callback, self.as(Void*), tol)
      end
    end
  end
end
