# crystal_wamr

TODO: Write a description here

Tested with [WAMR](https://github.com/bytecodealliance/wasm-micro-runtime) 1.2.3 and 2.1.0

As far as I understand WebAssembly is divided between two teams. The first sees WASM as a magical way to run a program written in any programming language on any operating system and hardware. If you are looking for something like this check out [Wasmer.cr](https://github.com/naqvis/wasmer-crystal) better.

The second considers WASM's WAT to be a modern standalone programming language for plug-ins and smart contracts. This shard offers several low-level utilities for WASM 32 also known as "browser WASM" without any extensions, including WASI. Even though the runtime I use ([WAMR](https://github.com/bytecodealliance/wasm-micro-runtime)) offers such extensions.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     crystal_wamr:
       github: onliniak/crystal_wamr
   ```

2. Run `shards install`

### Replit

1. Open replit.nix
2. Add pkgs.wamr

### FreeBSD

1. ``` git clone https://github.com/bytecodealliance/wasm-micro-runtime.git ```
2. https://github.com/bytecodealliance/wasm-micro-runtime/blob/main/product-mini/README.md
3. copy build/libiwasm.so and build/libvmlib.a to crystal project directory
4. ``` crystal build main.cr --release --no-debug --static ```
5. The ./main file should work on servers where iwasm is not installed

## Usage

The shard is divided into 3 parts: 

1. exec_once runs the WASM file and returns its result

```crystal
require "crystal_wamr"

wasm = CrystalWamr::WASM.new

p wasm.exec_once(File.read("spec/fib.wasm"), "fib", [8]) # => 21
```

2. exec loads the WASM file, runs several functions and closes the WASM file

```crystal
wasm.exec(File.read("spec/math.wasm"), {
  "add" => [8, 12],
  "power" => [3, 5]
  })
p wasm.return_hash # => {"add" => 20, "power" => 15}
```

3. exec_json lets you configure the library's operation with a json file.

```crystal
require "http/server"
require "crystal_wamr"
require "./config"

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
  wasm.exec_json(CrystalWamr::WamrConfig.from_json(File.read("config.json")), context.request.path.strip("/"))

  context.response.content_type = "text/plain"
  context.response.print wasm.return_hash.to_s
end

address = server.bind_tcp "0.0.0.0", 8080
server.listen
```
```crystal
# config.cr
module CrystalWamr
  class WASM
    def native_functions(sys, functions, index, url_path : String)
    end

    def native_functions(sys, functions, index, url_path : Array(Int32))
      argv = [] of Int32
      if sys.argv.size == 0
        argv = url_path
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
      end
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

### Strings

Tip: Crystal will remove blank characters.

```crystal
module CrystalWamr
  class WASM
return_string(File.read("string.wasm"), "string") # "Lorem ipsum dolor"
return_string(File.read("string.wasm"), "string", x) # Returns x characters. Default = 16.
  end
end
```

```c
const char* word = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";

extern int string(int s){
  int r = word[s];

  return r;
}
```

What if I don't know the length of the string ?

```crystal
module CrystalWamr
  class WASM
return_string(File.read("string.wasm"), "string") # "abcd"
  end
end
```

```c
const char* word = "abcd";

extern int string(int s){
  int r = word[s];

  return r;
}
```

### Arrays

```c
extern int array[0] = 0;
extern int size = 0;

extern void newarr(int a){
  array[size] = a;
  size++;
}

extern void newarra(int a){
  array[size] = a;
  size++;
}

extern void newarrb(int a){
  array[size] = a;
  size++;
}

extern int count(){
  return size;
}

extern int first(){
  return array[0]; 
}

extern int last(){
  return array[size - 1];
}
```

```crystal
 wasm.exec(File.read("x.wasm"), {
     "newarr" => [5],
     "newarra" => [10],
     "newarrb" => [15],
     "count" => [0],
     "first" => [0],
     "last" => [0]
     })
 p wasm.return_hash # {"newarr" => 5, "newarra" => 10, "newarrb" => 15, "count" => 3, "first" => 5, "last" => 15}
```

## Compilation

### Clang

1. https://github.com/WebAssembly/wasi-sdk/releases/latest
2. ```./wasi-sdk-23.0-x86_64-linux/bin/clang --target=wasm32 -nostdlib -Wl,--no-entry -Wl,--export-all -o main.wasm main.c```

### C4WA

1. https://github.com/kign/c4wa/releases/latest
2. ```./c4wa-compile-0.5/bin/c4wa-compile main.c```

## Expected performance

### Wizard mode

```c
extern int add(int a, int b){
  return a + b;
}
```

```
 hyperfine --warmup 3 './single_aot' './hash_aot' 'iwasm -f add add.wasm 8 12' -i -N
 Benchmark 1: ./single_aot
   Time (mean ± σ):      14.1 ms ±   4.1 ms    [User: 1.4 ms, System: 10.5 ms]
   Range (min … max):    10.2 ms …  36.4 ms    131 runs

   Warning: Statistical outliers were detected. Consider re-running this benchmark on a quiet system without any interferences from other programs. It might help to use the '--warmup' or '--prepare' options.

 Benchmark 2: ./hash_aot
   Time (mean ± σ):      13.5 ms ±   3.0 ms    [User: 1.1 ms, System: 10.6 ms]
   Range (min … max):     9.7 ms …  28.8 ms    202 runs

 Benchmark 3: iwasm -f add add.wasm 8 12
   Time (mean ± σ):      16.5 ms ±   6.3 ms    [User: 0.7 ms, System: 10.9 ms]
   Range (min … max):     9.9 ms …  59.4 ms    260 runs

   Warning: Statistical outliers were detected. Consider re-running this benchmark on a quiet system without any interferences from other programs. It might help to use the '--warmup' or '--prepare' options.

 Summary
   ./hash_aot ran
     1.05 ± 0.38 times faster than ./single_aot
     1.22 ± 0.54 times faster than iwasm -f add add.wasm 8 12
```

### I want to run the benchmark myself

```c
// from kign's c4wa README
extern int collatz(int N) {
    int len = 0;
    unsigned long n = N;
    do {
        if (n == 1)
            break;
        if (n % 2 == 0)
            n /= 2;
        else
            n = 3 * n + 1;
        len ++;
    }
    while(1);
    return len;
}
```

```crystal
def collatz(c, only_result : Bool)
  argv = Array(Int32 | Float64).new
  while c != 1
    if c % 2 > 0
      c = 3 * c + 1
    else
      c /= 2
    end
    argv << c
  end
  p argv unless only_result
  p "#N : #{argv.size}"
end
```

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
