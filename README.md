# crystal_wamr

TODO: Write a description here

Bindings to [WAMR](https://github.com/bytecodealliance/wasm-micro-runtime).
Tested with 1.2.3

Not works: AOT files

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     crystal_wamr:
       github: onliniak/crystal_wamr
   ```

2. Run `shards install`

## Usage

```crystal
require "crystal_wamr"

wasm = CrystalWamr::WASM.new

argv = Array(Int32).new
argv << 8
p wasm.exec(File.read("fib.wasm"), "fib", argv) # => fib function return: 21

argv = Array(Int32).new
argv << 2
argv << 3
p wasm.exec(File.read("math.wasm"), "pow", argv, "This is my custom message") # => This is my custom message 8
```

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/onliniak/crystal_wamr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Rafael Pszenny](https://github.com/onliniak) - creator and maintainer
