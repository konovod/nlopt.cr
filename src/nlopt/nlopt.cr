module NLopt
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

  class Solver
    @handle : LibNLopt::Opt?

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

    protected def initialize(@handle)
    end

    def clone
      Solver.new(@handle.try { |h| LibNLopt.copy(h) })
    end
  end
end
