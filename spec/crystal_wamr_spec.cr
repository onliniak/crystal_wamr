require "./spec_helper"

describe CrystalWamr do
  # TODO: Write tests

  it "works (single argument)" do
    wasm = CrystalWamr::WASM.new

    argv = Array(Int32).new
    argv << 8
    test = wasm.exec_once(File.read("spec/fib.wasm"), "fib", argv)
    test.should eq 21
  end

  it "works (multiple arguments)" do
    wasm = CrystalWamr::WASM.new

    wasm.exec(File.read("spec/array.wasm"), {
      "newarr"  => [5],
      "newarra" => [10],
      "newarrb" => [15],
      "count"   => [0],
      "first"   => [0],
      "last"    => [0],
    })
    test = wasm.return_hash.to_s
    test.should eq %({"newarr" => 5, "newarra" => 10, "newarrb" => 15, "count" => 3, "first" => 5, "last" => 15})
  end

  it "works (HTTP)" do
    wasm = CrystalWamr::WASM.new
    context_request_resource = "/27"
    path = context_request_resource # .strip "/"

    config = CrystalWamr::WamrConfig.from_json(%({
      "file": "spec/math.wasm",
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

    wasm.exec_json(config, path)
    test = wasm.return_hash.to_s
    test.should eq %({"add" => 5, "mul" => 10})
  end

  it "works (HTTP -> depth 2)" do
    wasm = CrystalWamr::WASM.new
    context_request_resource = "/5/12"
    path = context_request_resource # .strip "/"

    config = CrystalWamr::WamrConfig.from_json(%({
      "file": "spec/math.wasm",
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
                  "name": "hypot",
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

    wasm.exec_json(config, path)
    test = wasm.return_hash.to_s
    test.should eq %({"add" => 15, "mul" => 30})
  end

  it "works (Strings)" do
    test = crystal_wamr_return_string(File.read("spec/string.wasm"), "string")
    test.should eq "abcd"
  end

  # it "Create AOT", tags: "prepare-aot-benchmark-linux" do

  #   stdout = IO::Memory.new
  #   Process.run("iwasm", ["--version"], output: stdout)
  #   version = stdout.to_s[6..].strip("\n")

  #   url = "https://github.com/bytecodealliance/wasm-micro-runtime/releases/download/WAMR-#{version}/wamrc-#{version}-x86_64-ubuntu-20.04.tar.gz"

  #   Process.run("curl", ["-L", url, "--output", "wamrc-#{version}-x86_64-ubuntu-20.04.tar.gz"])
  #   Process.run("tar", ["-zxvf", "wamrc-#{version}-x86_64-ubuntu-20.04.tar.gz"])
  #   Process.run("./wamrc", ["--enable-segue", "-o", "spec/collatz.aot", "spec/collatz.wasm"]) #unless File.exists?("spec/collatz.aot")

  #   File.delete("wamrc-#{version}-x86_64-ubuntu-20.04.tar.gz")
  # end

  it "Collatz AOT benchmark", tags: "aot-benchmark" do
    wasm = CrystalWamr::WASM.new
    # file = File.read("spec/collatz.aot")
    file = "\u0000aot\u0003\u0000\u0000\u0000\u0000\u0000\u0000\u00000\u0000\u0000\u0000\u0002\u0000\u0000\u0000\u0001\u0000>\u0000\u0001\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000x86_64\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0001\u0000\u0000\u0000t\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0001\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0001\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0001\u0000\u0000\u0000\u0000\u0000\u0001\u0000\u0001\u0000\u007F\u007F\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0001\u0000\u0000\u0000\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\xFF\xFF\xFF\xFF\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\xFF\xFF\xFF\xFF\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0002\u0000\u0000\u00000\u0000\u0000\u0000\u0000\u0000\u0000\u0000Hc\xCE1\xC0H\x83\xF9\u0001t\u001F\u000F\u001FD\u0000\u0000H\x89\xCAH\xD1\xEA\xF6\xC1\u0001H\x8DLI\u0001H\u000FD\xCA\xFF\xC0H\x83\xF9\u0001u\xE6\xC3\u0000\u0003\u0000\u0000\u0000\u0014\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0004\u0000\u0000\u0000\u0004\u0000\u0000\u0000\u0004\u0000\u0000\u0000\u0014\u0000\u0000\u0000\u0001\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\b\u0000collatz\u0000\u0005\u0000\u0000\u0000\f\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000"

    test = wasm.exec_once(file, "collatz", [626331])
    test.should eq 508 # ~ 7ms
  end

  it "Collatz Native benchmark", tags: "native-benchmark" do
    test = collatz 626331
    test.should eq 508 # ~ 300µs (25 times faster)
  end
end
