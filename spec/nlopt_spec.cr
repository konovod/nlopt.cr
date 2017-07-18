require "./spec_helper"

describe NLopt do
  it "works" do
    LibNLopt.version(out major, out minor, out bugfix)
    puts "NLopt Version: #{major}.#{minor}.#{bugfix}"
  end

  it "can create, copy and free solvers" do
    s1 = NLopt::Solver.new(NLopt::Algorithm::LnCobyla, 100)
    s1.dimension.should eq 100
    (s1.algorithm.to_s[0..5]).should eq "COBYLA"

    s2 = s1.clone
    s1.free
    expect_raises(Exception) do
      s1.algorithm
    end
    s2.algorithm.should eq NLopt::Algorithm::LnCobyla
  end

  it "can optimize function without constraints" do
    s1 = NLopt::Solver.new(NLopt::Algorithm::LnCobyla, 2)
    s1.objective = ->(x : Slice(Float64)) { (x[0] - 3)**2 + (x[1] - 2)**2 }
    res, x, f = s1.solve
    res.should eq NLopt::Result::XtolReached
    x[0].should be_close(3, 1e-7)
    x[1].should be_close(2, 1e-7)
    f.should be_close(0, 1e-7)
  end

  it "behave nicely when function raises" do
    s1 = NLopt::Solver.new(NLopt::Algorithm::LnCobyla, 2)
    s1.objective = ->(x : Slice(Float64)) { raise "exception in objective" }
    expect_raises(Exception, "exception in objective") do
      s1.solve
    end
  end

  it "can set bounds and other options for variables" do
    s1 = NLopt::Solver.new(NLopt::Algorithm::LnCobyla, 2)
    s1.variables[0].set(min: 4, guess: 50)
    s1.variables[1].set(max: 2, initial_step: 1.0)
    s1.objective = ->(x : Slice(Float64)) { (x[0] - 3)**4 + (x[1] - 2)**2 }
    res, x, f = s1.solve
    res.should eq NLopt::Result::XtolReached
    x[0].should be_close(4, 1e-7)
    x[1].should be_close(2, 1e-7)
    f.should be_close(1.0, 1e-7)
  end

  it "works with separate function for gradient" do
    s1 = NLopt::Solver.new(NLopt::Algorithm::LdMma, 2)
    s1.objective = ->(x : Slice(Float64)) { (x[0] - 1) * (x[1] - 2)**2 }
    s1.obj_gradient = ->(x : Slice(Float64), grad : Slice(Float64)) do
      grad[0] = (x[1] - 2)**2
      grad[1] = 2*(x[0] - 1)*(x[1] - 2)
    end
    s1.variables[0].min = 2.0
    s1.variables[1].max = 10.0
    res, x, f = s1.solve
    res.should eq NLopt::Result::XtolReached
    x[1].should be_close(2, 1e-7)
    f.should be_close(0, 1e-7)
  end

  it "works with combined function for gradient" do
    s1 = NLopt::Solver.new(NLopt::Algorithm::LdMma, 2)
    s1.objective = ->(x : Slice(Float64), grad : Slice(Float64)?) do
      if grad
        grad[0] = (x[1] - 2)**2
        grad[1] = 2*(x[0] - 1)*(x[1] - 2)
      end
      (x[0] - 1) * (x[1] - 2)**2
    end
    s1.variables[0].min = 2.0
    s1.variables[1].max = 10.0
    res, x, f = s1.solve
    res.should eq NLopt::Result::XtolReached
    x[1].should be_close(2, 1e-7)
    f.should be_close(0, 1e-7)
  end
end
