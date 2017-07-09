require "./spec_helper"

describe Nlopt do
  # TODO: Write tests

  it "works" do
    LibNLOPT.version(out major, out minor, out bugfix)
    puts "NLOPT Version: #{major}.#{minor}.#{bugfix}"
  end
end
