[![Linux CI](https://github.com/konovod/nlopt/actions/workflows/linux.yml/badge.svg)](https://github.com/konovod/nlopt/actions/workflows/linux.yml)
[![Windows CI](https://github.com/konovod/nlopt/actions/workflows/windows.yml/badge.svg)](https://github.com/konovod/nlopt/actions/workflows/windows.yml) 
[![MacOSX CI](https://github.com/konovod/nlopt/actions/workflows/macosx.yml/badge.svg)](https://github.com/konovod/nlopt/actions/workflows/macosx.yml) 
# NLOpt
Idea is to provide wrappers for most performant opensource optimization tools that are available. This shard is about nonlinear optimization.

According to http://plato.asu.edu/bench.html IPOPT performs pretty fast, almost on par with commercial solvers.
According to  http://repositorium.sdum.uminho.pt/bitstream/1822/39109/1/Eliana_ICNAAM2014.pdf NLopt is slower, but still finds optimum.

The problem is that IPOPT is pretty complex to get installed, have a lot of dependencies, so it perhaps doesn't fit in the general-purpose scientific library. NLopt has also much simpler API.

So this is a wrapper of [NLopt library](https://nlopt.readthedocs.io/en/latest/).

## Installation

1. Install NLopt from package manager (`apt install libnlopt0` for Ubuntu, https://aur.archlinux.org/packages/nlopt for Arch).
2. Add this to your application's `shard.yml`:

```yaml
dependencies:
  nlopt:
    github: konovod/nlopt
```

On Windows:
  you can get compiled version 2.4.2 using instructions from this page: http://ab-initio.mit.edu/wiki/index.php?title=NLopt_on_Windows
  Basically
  1. download http://ab-initio.mit.edu/nlopt/nlopt-2.4.2-dll64.zip
  2. unpack, rename `libnlopt-0.def` to `nlopt.def`, call `lib /def:nlopt.def /machine:x64` in the unpacked directory to generate `nlopt.lib`
  3. copy `libnlopt-0.dll` to your program directory (rename to `nlopt.dll`)
  4. copy `nlopt.lib` to where your Crystal looks for lib files

Alternatively, you can compile latest (2.9.1) version from source (https://github.com/stevengj/nlopt). Windows CI Action does it too, so you can grab dll library from it's artifacts. Note that it depends on msvcp140.dll.

## Usage

```crystal
require "nlopt"
```

you can check `spec` directory for simple examples.
Supported features:
 - [x] creating and freeing solvers with any of 43 supported algorithms
```crystal
s1 = NLopt::Solver.new(NLopt::Algorithm::LnCobyla, 100)
s1.dimension.should eq 100
(s1.algorithm.to_s[0..5]).should eq "COBYLA"
s2 = s1.clone
s1.free
expect_raises(Exception) do
  s1.algorithm
end
s2.algorithm.should eq NLopt::Algorithm::LnCobyla
```
 - [x] simple optimization of given function
```crystal
s1 = NLopt::Solver.new(NLopt::Algorithm::LnCobyla, 2)
s1.objective = ->(x : Slice(Float64)) { (x[0] - 3)**2 + (x[1] - 2)**2 }
res, x, f = s1.solve
res.should eq NLopt::Result::XtolReached
x[0].should be_close(3, 1e-7)
x[1].should be_close(2, 1e-7)
f.should be_close(0, 1e-7)
```
 - [x] setting parameters of solver
```crystal
s1 = NLopt::Solver.new(NLopt::Algorithm::LnCobyla, 100)
s1.optim_dir = NLopt::Direction::Maximize # default is minimize
# stopval, ftol_rel, ftol_abs, xtol_rel, maxeval, maxtime, population, vector_storage are supported. Check nlopt documentation for description
s1.stopval = -1e6
# local_optimizer for algorithms that support it
s1 = NLopt::Solver.new(NLopt::Algorithm::Auglag, 100)
s1_local = NLopt::Solver.new(NLopt::Algorithm::LnCobyla, 100)
s1.local_optimizer(s1_local)
```
 - [x] setting minimum and maximum bound, initial guess and initial step for variables
```crystal
s1 = NLopt::Solver.new(NLopt::Algorithm::LnCobyla, 2)
s1.variables[0].min = 2.0
s1.variables[1].max = 10.0
# or several params at once:
s1.variables[0].set(min: 4, guess: 50)
s1.variables[1].set(max: 2, initial_step: 1.0) 
```
 - [x] use separate function for gradient calculation on calculate gradient together with objective function
```crystal
s1 = NLopt::Solver.new(NLopt::Algorithm::LdMma, 2)
s1.objective = ->(x : Slice(Float64)) { (x[0] - 1) * (x[1] - 2)**2 }
s1.obj_gradient = ->(x : Slice(Float64), grad : Slice(Float64)) do
  grad[0] = (x[1] - 2)**2
  grad[1] = 2*(x[0] - 1)*(x[1] - 2)
end
# or:
s1 = NLopt::Solver.new(NLopt::Algorithm::LdMma, 2)
s1.objective = ->(x : Slice(Float64), grad : Slice(Float64)?) do
  if grad
    grad[0] = (x[1] - 2)**2
    grad[1] = 2*(x[0] - 1)*(x[1] - 2)
  end
  (x[0] - 1) * (x[1] - 2)**2
end
```
 - [x] Constraints in forms of equalities and inequalities
```crystal
s1 = NLopt::Solver.new(NLopt::Algorithm::LdMma, 2)
s1.xtol_rel = 1e-4
s1.objective = ->(x : Slice(Float64), grad : Slice(Float64)?) do
  if grad
    grad[0] = 0.0
    grad[1] = 0.5 / Math.sqrt(x[1])
  end
  Math.sqrt(x[1])
end
a = 2
b = 0
s1.constraints << NLopt.inequality do |x, grad|
  if grad
    grad[0] = 3 * a * (a*x[0] + b) * (a*x[0] + b)
    grad[1] = -1.0
  end
  ((a*x[0] + b) * (a*x[0] + b) * (a*x[0] + b) - x[1])
end
s1.constraints << NLopt.equality do |x, grad|
  if grad
    grad[0] = 1.0
    grad[1] = 1.0
  end
  x[0] + x[1] - 3
end
```
 - [x] Vector-valued constraints
```crystal
s1.constraints << NLopt.inequalities(2) do |x, grad, result|
  if grad
    grad[0] = 3 * a1 * (a1*x[0] + b1) * (a1*x[0] + b1)
    grad[1] = -1.0
    grad[2] = 3 * a2 * (a2*x[0] + b2) * (a2*x[0] + b2)
    grad[3] = -1.0
  end
  result[0] = ((a1*x[0] + b1) * (a1*x[0] + b1) * (a1*x[0] + b1) - x[1])
  result[1] = ((a2*x[0] + b2) * (a2*x[0] + b2) * (a2*x[0] + b2) - x[1])
end
```

 - [x] Forced termination
 You can raise an exception in optimization function to abort optimization early but this won't keep latest result.
 You can also do `#force_stop` to terminate optimization while keeping best point found:
``` 
  s1 = NLopt::Solver.new(NLopt::Algorithm::LdMma, 2)
  timer = 100
  s1.objective = ->(x : Slice(Float64), grad : Slice(Float64)?) do
    timer -= 1
    s1.force_stop if timer <= 100
    if grad
      grad[0] = (x[1] - 2)**2
      grad[1] = 2*(x[0] - 1)*(x[1] - 2)
    end
    (x[0] - 1) * (x[1] - 2)**2
  end
  res, x, f = s1.solve  
  res # => NLopt::Result::ForcedStop
  x   # => [4.0, 0.0]
  f   # => 12.0
```

 - [x] Algorithm-specific parameters
```crystal
    s1.params["inner_maxeval"] = 100 # set upper bound on the number of "inner" iterations of the algorithm MMA
    s1.params["wrong_param"] = 10 # for now, there is no way to check that parameter even exists

    puts s1.params.all_changed # => {"inner_maxeval" => 100.0, "wrong_param" => 10.0}
```
 - [x] setting random seed
```crystal
NLopt.srand # will randomize seed
NLopt.srand(12345_u64) # will set fixed seed
```
 - [x] Preconditioning with approximate Hessians for objective function
 ```crystal
     s1.precondition = ->(x : Slice(Float64), hessian : Slice(Float64)) do
      hessian[0] = 1.0
      hessian[1] = 0.0
      hessian[2] = 1.0
      hessian[3] = 0.0
    end

    # or, in a more effecient way

     s1.precondition = ->(x : Slice(Float64), v : Slice(Float64), vpre : Slice(Float64)) do
      vpre[0] = v[0]
      vpre[1] = v[1]
    end
 ```
 - [ ] Preconditioning with approximate Hessians for constraints
 - [x] Get number of objective function evaluations (`Solver#num_evals`) to estimate efficiency
 - [x] Version number
```crystal
LibNLopt.version(out major, out minor, out bugfix)
puts "NLopt Version: #{major}.#{minor}.#{bugfix}"
```

## Contributing

1. Fork it ( https://github.com/konovod/nlopt.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request
