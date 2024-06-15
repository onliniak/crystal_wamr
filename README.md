# crystal_wamr

TODO: Write a description here

Bindings to [WAMR](https://github.com/bytecodealliance/wasm-micro-runtime).
Tested with 1.2.3

For production apps use https://github.com/naqvis/wasmer-crystal

Why? I wanted to have user-submitted functions on free hosting without sudo, but with SSH.

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

## Known Issues

### Invalid memory access (signal 11) at address 0x0

Use https://github.com/naqvis/wasmer-crystal

For some reason grain lang and TinyGO reject argv array.
[c4WA](https://github.com/kign/c4wa) works. I haven't checked emscripten but it likely works.

### AssemblyScript: "Exception: failed to call unlinked import function (env, abort)".

https://github.com/bytecodealliance/wasm-micro-runtime/issues/510

### Strings

It seems that on the default settings you can not return array. Only single numeric value. But I could be wrong. 
EDIT: https://github.com/bytecodealliance/wasm-micro-runtime/issues/263

### No AOT support

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
