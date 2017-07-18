require "./spec_helper"

def test_constraint(a, b)
  NLopt::SingleConstraint.new(1e-8) do |x, grad|
    if grad
      grad[0] = 3 * a * (a*x[0] + b) * (a*x[0] + b)
      grad[1] = -1.0
    end
    ((a*x[0] + b) * (a*x[0] + b) * (a*x[0] + b) - x[1])
  end
end

describe NLopt do
  it "can work with nonlinear constraints" do
    s1 = NLopt::Solver.new(NLopt::Algorithm::LdMma, 2)
    s1.xtol_rel = 1e-4
    s1.objective = ->(x : Slice(Float64), grad : Slice(Float64)?) do
      if grad
        grad[0] = 0.0
        grad[1] = 0.5 / Math.sqrt(x[1])
      end
      Math.sqrt(x[1])
    end
    s1.constraints << test_constraint(2, 0)
    s1.constraints << test_constraint(-1, 1)
    s1.variables[1].min = 0.0
    s1.variables[0].guess = 1.234
    s1.variables[1].guess = 5.678
    res, x, f = s1.solve
    res.should eq NLopt::Result::XtolReached
    x[0].should be_close(0.333334, 1e-5)
    x[1].should be_close(0.296296, 1e-5)
    f.should be_close(0.544330847, 1e-5)
  end
end
