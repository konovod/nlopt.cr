require "./spec_helper"

describe NLopt do
  # TODO: Write tests

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
    s1.xtol_rel = 1e-8
    s1.objective = ->(x : Slice(Float64)) { (x[0] - 3)**2 + (x[1] - 2)**2 }
    res, x, f = s1.solve
    res.should eq NLopt::Result::XtolReached
    x[0].should be_close(3, 1e-7)
    x[1].should be_close(2, 1e-7)
    f.should be_close(0, 1e-7)
  end

  it "behave nicely when function raises" do
    s1 = NLopt::Solver.new(NLopt::Algorithm::LnCobyla, 2)
    s1.xtol_rel = 1e-8
    s1.objective = ->(x : Slice(Float64)) { raise "exception in objective" }
    expect_raises(Exception, "exception in objective") do
      s1.solve
    end
  end
end
