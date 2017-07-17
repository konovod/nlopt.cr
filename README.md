# NLOpt
Idea is to provide wrappers for most performant opensource optimization tools that are available. This shard is about nonlinear optimization.

According to http://plato.asu.edu/bench.html IPOPT performs pretty fast, almost on par with commercial solvers.
According to  http://repositorium.sdum.uminho.pt/bitstream/1822/39109/1/Eliana_ICNAAM2014.pdf NLopt is slower, but still finds optimum.

The problem is that IPOPT is pretty complex to get installed, have a lot of dependencies, so it perhaps doesn't fit in the general-purpose scientific library. NLopt has also much simpler API.

So this is a wrapper of [NLopt library](http://ab-initio.mit.edu/wiki/index.php/NLopt).

## Installation

1. Install NLopt from package manager (`apt install libnlopt0` for Ubuntu, https://aur.archlinux.org/packages/nlopt for Arch).
2. Add this to your application's `shard.yml`:

```yaml
dependencies:
  nlopt:
    github: konovod/nlopt
```

## Usage

```crystal
require "nlopt"
```

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Contributing

1. Fork it ( https://github.com/konovod/nlopt/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request
