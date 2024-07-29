# crystal_wamr

TODO: Write a description here

Bindings to [WAMR](https://github.com/bytecodealliance/wasm-micro-runtime). </br>
Tested with 1.2.3 and 2.1.0

**Pure WASM a.k.a "browser" engine** with crystal std library and inheritance. 

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     crystal_wamr:
       github: onliniak/crystal_wamr
   ```

2. Run `shards install`

## Usage

CLI

```crystal
require "crystal_wamr"

wasm = CrystalWamr::WASM.new

wasm.exec(File.read("fib.aot"), {"fib" => [8]})
p wasm.return_hash["fib"] # => 21
```

Server

```crystal
require "http/server"
require "crystal_wamr"
require "json"

wasm = CrystalWamr::WASM.new
config = CrystalWamr::WamrConfig.from_json(%({
  "file": "lib/crystal_wamr/spec/math.wasm",
  "func": [
    {
      "name": "add",
      "input": [
        {
          "argv": {
            "int": 2
          }
        },
        {
          "argv": {
            "var": "$URL",
            "sys": {
              "name": "cbrt",
              "argv": []
            }
          }
        }
      ]
    },
    {
      "name": "mul",
      "input": [
        {
          "argv": {
            "int": 2
          }
        },
        {
          "argv": {
            "var": "add"
          }
        }
      ]
    }
  ]
  }))

server = HTTP::Server.new do |context|
  wasm.exec_json(config, context.request.path.strip("/"))
  
  context.response.content_type = "text/plain"
  context.response.print wasm.return_hash.to_s
end

address = server.bind_tcp "0.0.0.0", 8080
server.listen
```
```crystal
module CrystalWamr
  class WASM
    def capture(&block : Int32 -> Int32)
      # block argument is used, so block is turned into a Proc
      block
    end

    def native_functions(sys, functions, index, url_path : String)
    end

    def native_functions(sys, functions, index, url_path : Int32)
      argv = [] of Int32
      if sys.argv.size == 0
        argv[0] = url_path
      else
        argv = sys.argv
      end
      proc = capture do
        if sys.name == "cbrt"
          functions[index] << Math.cbrt(argv[0]).to_i
        end
        if sys.name == "hypot"
          functions[index] << Math.hypot(argv[0], argv[1]).to_i
        end
        0
      end
      proc.call(1)
    end
  end
end
```
```
You can run several functions simultaneously. 

file = filename with extension .aot or .wasm
name = name of the WASM function

input 
  argv = array of Int32 numbers
    int = array Int32
    var = use number from web address or result of another function
    sys = pass the result to the crystal function
      name = function name
      argv = function arguments : Int32  

The add function retrieves the web address. For example, myweb.eu/27 => $URL = 27.
It then passes $URL to the Math.cbrt function and we have 3. Finally, it adds the result to 2.

The mul function multiplies the result of the add function (5 in the example) by 2. 
```

TODO: Write usage instructions here

## Known Issues

### Invalid memory access (signal 11) at address 0x0

If you are using AOT make sure wamrc is in the same version as iwasm

#### No WASI Support
Use [c4WA](https://github.com/kign/c4wa) or clang with --nostdlib --target=wasm32

If you absolutely need WASI PR welcome.

### Performance

The identical code in the crystal and C4WA has a similar speed. However, it is quite possible that I made some serious mistakes in the code and the speed of this library will be lower than iwasm. If it bothers you PR welcome.

### Strings

Use https://github.com/naqvis/wasmer-crystal

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
