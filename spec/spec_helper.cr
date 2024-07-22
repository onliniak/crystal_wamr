require "spec"
require "../src/crystal_wamr"
require "benchmark"

def collatz(c, only_result : Bool)
  # start : Float64 = c.to_f64
  argv = Array(Int32 | Float64).new
  # argv << start
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
