require "./spec_helper"

describe CrystalWamr do
  # TODO: Write tests

  it "works (single argument)" do
    wasm = CrystalWamr::WASM.new

    argv = Array(Int32).new
    argv << 8
    test = wasm.exec(File.read("spec/fib.wasm"), "fib", argv)
    test.should eq "fib function return: 21"
  end

  it "works (multiple arguments)" do
    wasm = CrystalWamr::WASM.new

    argv = Array(Int32).new
    argv << 2
    argv << 3
    test = wasm.exec(File.read("spec/math.wasm"), "pow", argv)
    test.should eq "pow function return: 8"
  end

  it "works (custom message)" do
    wasm = CrystalWamr::WASM.new

    argv = Array(Int32).new
    argv << 2
    argv << 3
    test = wasm.exec(File.read("spec/math.wasm"), "pow", argv, "This is my custom message")
    test.should eq "This is my custom message 8"
  end

   it "Collatz AOT benchmark", tags: "benchmark" do
    Process.new("./wamrc", ["-o", "spec/collatz.aot", "spec/collatz.wasm"]) unless File.exists?("spec/collatz.aot")
    sleep 1

    if File.exists?("spec/collatz.aot")
      Benchmark.bm do |x|
        x.report("WAMR AOT Bindings") do
          wasm = CrystalWamr::WASM.new

          argv = Array(Int32).new
          argv << 626331
          p wasm.exec(File.read("spec/collatz.aot"), "collatz", argv)
        end
        x.report("Native Crystal") do
          collatz 626331, true
        end
      end
    
end
