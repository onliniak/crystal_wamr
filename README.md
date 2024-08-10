# crystal_wamr

TODO: Write a description here

Tested with [WAMR](https://github.com/bytecodealliance/wasm-micro-runtime) 1.2.3 and 2.1.0

**No WASI Support** </br>
**No Imports Support**

As far as I understand WebAssembly is divided between two teams. The first sees WASM as a magical way to run a program written in any programming language on any operating system and hardware. If you are looking for something like this check out [Wasmer.cr](https://github.com/naqvis/wasmer-crystal) better.

The second considers WASM's WAT to be a modern standalone programming language for plug-ins and smart contracts. This shard offers several low-level utilities for WASM 32 also known as "browser WASM" without any extensions, including WASI. Even though the runtime I use offers such extensions.

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

```sh
 git clone https://github.com/bytecodealliance/wasm-micro-runtime.git
 cd wasm-micro-runtime/product-mini/platforms/freebsd
 mkdir build && cd build
 cmake ..
 make
 mv iwasm /usr/local/bin/iwasm
 mv libiwasm.so /usr/local/lib/libiwasm.so
 mv libvmlib.a /usr/local/lib/libvmlib.a
 crystal init app myapp
 cd myapp # && shards install
 cd lib/crystal_wamr
 iwasm --version # check if iwasm is installed
 crystal spec # check if libiwasm.so is installed
```

Server

You must add -Wl,-rpath=ABSOLUTE_PATH to gcc.

0. ``` rm /usr/local/lib/libiwasm.so /usr/local/lib/libvmlib.a /usr/local/bin/iwasm ```
1. ``` cd wasm-micro-runtime/product-mini/platforms/freebsd/build && make ```
2. ``` mv iwasm.so /server/iwasm.so && mv libvmlib.a /server/libvmlib.a && mv /usr/local/bin/crystal /server/crystal && mv /usr/local/bin/shards /server/shards  ```
3. Build on server.
```sh
chmod +x crystal
chmod +x shards
mkdir lib/crystal # Crystal will look for .so files in this directory by default. Problem is, the executable itself does not use this directory.
cp libiwasm.so lib/crystal/libiwasm.so
cp libvmlib.a lib/crystal/libvmlib.a
./crystal init app test
mkdir extra
cp libiwasm.so test/extra/libiwasm.so
cp libvmlib.a test/extra/libvmlib.a
mv crystal test/crystal
mv shards test/shards
cd test
./shards install
nano lib/crystal_wamr/src/crystal_wamr.cr # add new line before @[Link("iwasm")] => @[Link(ldflags: "-Wl,-rpath=/usr/home/onliniak/domains/test.onliniak.ct8.pl/public_html/test/extra")] # !!! MUST BE ABSOLUTE PATH
touch main.cr
./crystal build main.cr
./main # check if linking works
```


## Usage

The shard is divided into 3 parts: 

0. ``` cd lib/crystal_wamr && crystal spec ``` => example wasm files in spec directory

1. exec_once runs the WASM file and returns its result

```crystal
require "crystal_wamr"

wasm = CrystalWamr::WASM.new

p wasm.exec_once(File.read("lib/crystal_wamr/spec/fib.wasm"), "fib", [8]) # => 21
```

2. exec loads the WASM file, runs several functions and closes the WASM file

```crystal
 wasm.exec(File.read("lib/crystal_wamr/array.wasm"), {
     "newarr" => [5],
     "newarra" => [10],
     "newarrb" => [15],
     "count" => [0],
     "first" => [0],
     "last" => [0]
     })
 p wasm.return_hash # {"newarr" => 5, "newarra" => 10, "newarrb" => 15, "count" => 3, "first" => 5, "last" => 15}
```
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

2.1. Read strings

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

3. exec_json lets you configure the library's operation with a json file.

```crystal
require "http/server"
require "crystal_wamr"
require "./config"

wasm = CrystalWamr::WASM.new
ENV["PORT"] = "8080"
ENV["HOST"] = "0.0.0.0"

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
  wasm.exec_json(CrystalWamr::WamrConfig.from_json(File.read("config.json")), context.request.path)

  context.response.content_type = "text/plain"
  context.response.print wasm.return_hash.to_s
end

address = server.bind_tcp ENV["HOST"], ENV["PORT"].to_i
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
    elsif sys.argv.size > 0
      argv = sys.argv
      else
        argv = url_path
      end
      if sys.name == "cbrt"
        functions[index] << Math.cbrt(argv[0]).to_i
      end
      if sys.name == "hypot"
        functions[index] << Math.hypot(argv[0], argv[1]).to_i
      end
    end
  end
end
```
### JSON
```json
{
"file": "lib/crystal_wamr/spec/math.wasm",
 ```
file = filename with extension .aot or .wasm

```json
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
```
```
func
  name = name of the WASM function
  input = array of Int32 function parameters
    argv
      int = const int32
      var = The result from the execution of the WASM function
        $URL # curl myweb.eu/27/17/10
          argv[0] = 27
          argv[1] = 17
          argv[2] = 10
      sys # looking for line: if sys.name == "cbrt" inside config.cr
        name
        argv = array of arguments for native crystal function. Leave empty when $URL in use.

```
```
]
  })
```
```
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

```bash
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

### Another example

``` cd lib/crystal_wamr && crystal spec --tag "aot-benchmark" ```
``` cd lib/crystal_wamr && crystal spec --tag "native-benchmark" ```

[on server] The identical code in the crystal and C4WA -> AOT has a similar speed. However, it is quite possible that I made some serious mistakes in the code and the speed of this library will be lower than iwasm. If it bothers you PR welcome.

## Known Issues

### Invalid memory access (signal 11) at address 0x0

- If you are using AOT make sure wamrc is in the same version as iwasm.
- This shard don't support WASI and Imports.
- The function you are trying to run returns an array, char or any other type that is not int, double, float, long

### Regex::MatchData

Fixed ?

### Stack guard pages

Wrong iwasm installed
Try ``` cd lib/crystal_wamr && crystal spec ```

Reinstall shard: ``` rm shard.lock && shards install ```

```
Failed to init stack guard pages
[10:07:17:747 - 2781C4C18000]: wasm_runtime_malloc failed: memory hasn't been initialized.

Invalid memory access (signal 11) at address 0x0
[0x417699] ???
[0x417668] ???
[0x7def2f] ???
[0x7de4f4] ???
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
