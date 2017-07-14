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
    s1.objective = ->(x : Slice(Float64)) { (x[0] - 3)**2 + (x[1] - 2)**2 }
    pp s1.solve
  end
end
