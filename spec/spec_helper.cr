require "spec"
require "./../src/crystal_wamr"

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
      if sys.name == "cbrt"
        functions[index] << Math.cbrt(argv[0]).to_i
      end
      if sys.name == "hypot"
        functions[index] << Math.hypot(argv[0], argv[1]).to_i
      end
    end
  end
end

def collatz(c) # , only_result : Bool)
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
  # p argv unless only_result
  # p "#N : #{argv.size}"
  return argv.size
end

File.write("spec/math.wasm", "\u0000asm\u0001\u0000\u0000\u0000\u0001\a\u0001`\u0002\u007F\u007F\u0001\u007F\u0003\u0006\u0005\u0000\u0000\u0000\u0000\u0000\u0005\u0003\u0001\u0000\u0000\a(\u0006\u0003add\u0000\u0000\u0003sub\u0000\u0001\u0003mul\u0000\u0002\u0003div\u0000\u0003\u0003pow\u0000\u0004\u0006memory\u0002\u0000\n\xDB\u0002\u0005\a\u0000 \u0000 \u0001j\v\a\u0000 \u0000 \u0001k\v\a\u0000 \u0000 \u0001l\v\a\u0000 \u0000 \u0001m\v\xB8\u0002\u0001\u0001\u007F\u0002\u007FA\u0001!\u0002A\u0001 \u0001tA\u0000 \u0001A I\e \u0000A\u0002F\r\u0000\u001A \u0001A\u0000L\u0004@A\u007FA\u0001 \u0001A\u0001q\e \u0000A\u007FF\r\u0001\u001A \u0001E \u0000A\u0001Fr\f\u0001\u0005 \u0001A\u0001F\u0004@ \u0000\f\u0002\u0005 \u0001A\u0002F\u0004@ \u0000 \u0000l\f\u0003\u0005 \u0001A H\u0004@\u0002@\u0002@\u0002@\u0002@\u0002@\u0002@A\u001F \u0001gk\u000E\u0005\u0004\u0003\u0002\u0001\u0000\u0005\v \u0000A\u0001 \u0001A\u0001q\e!\u0002 \u0001A\u0001v!\u0001 \u0000 \u0000l!\u0000\v \u0000 \u0002l \u0002 \u0001A\u0001q\e!\u0002 \u0001A\u0001v!\u0001 \u0000 \u0000l!\u0000\v \u0000 \u0002l \u0002 \u0001A\u0001q\e!\u0002 \u0001A\u0001v!\u0001 \u0000 \u0000l!\u0000\v \u0000 \u0002l \u0002 \u0001A\u0001q\e!\u0002 \u0001A\u0001v!\u0001 \u0000 \u0000l!\u0000\v \u0000 \u0002l \u0002 \u0001A\u0001q\e!\u0002\v \u0002\f\u0004\v\v\v\v\u0003@ \u0001\u0004@ \u0000 \u0002l \u0002 \u0001A\u0001q\e!\u0002 \u0001A\u0001v!\u0001 \u0000 \u0000l!\u0000\f\u0001\v\v \u0002\v\v\u0000\u0017\u0010sourceMappingURL\u0005false") unless File.exists?("spec/math.wasm")

File.write("spec/fib.wasm", "\u0000asm\u0001\u0000\u0000\u0000\u0001\x86\x80\x80\x80\u0000\u0001`\u0001\u007F\u0001\u007F\u0003\x82\x80\x80\x80\u0000\u0001\u0000\u0004\x84\x80\x80\x80\u0000\u0001p\u0000\u0000\u0005\x83\x80\x80\x80\u0000\u0001\u0000\u0001\u0006\x81\x80\x80\x80\u0000\u0000\a\x90\x80\x80\x80\u0000\u0002\u0006memory\u0002\u0000\u0003fib\u0000\u0000\n\xA4\x80\x80\x80\u0000\u0001\x9E\x80\x80\x80\u0000\u0000\u0002@ \u0000A\u0002N\r\u0000 \u0000\u000F\v \u0000A\u007Fj\u0010\u0000 \u0000A~j\u0010\u0000j\v") unless File.exists?("spec/fib.wasm")

File.write("spec/array.wasm", "\u0000asm\u0001\u0000\u0000\u0000\u0001\t\u0002`\u0001\u007F\u0000`\u0000\u0001\u007F\u0003\a\u0006\u0000\u0000\u0000\u0001\u0001\u0001\u0005\u0003\u0001\u0000\u0001\u0006\v\u0002\u007F\u0001A\u0000\v\u007F\u0001A\u0000\v\aM\t\u0004size\u0003\u0000\u0005array\u0003\u0001\u0006memory\u0002\u0000\u0006newarr\u0000\u0000\anewarra\u0000\u0001\anewarrb\u0000\u0002\u0005count\u0000\u0003\u0005first\u0000\u0004\u0004last\u0000\u0005\nd\u0006\u0016\u0000#\u0001#\u0000A\u0004lj \u00006\u0000\u0000#\u0000A\u0001j$\u0000\v\u0016\u0000#\u0001#\u0000A\u0004lj \u00006\u0000\u0000#\u0000A\u0001j$\u0000\v\u0016\u0000#\u0001#\u0000A\u0004lj \u00006\u0000\u0000#\u0000A\u0001j$\u0000\v\u0004\u0000#\u0000\v\a\u0000#\u0001(\u0000\u0000\v\u0010\u0000#\u0001#\u0000A\u0001kA\u0004lj(\u0000\u0000\v") unless File.exists?("spec/array.wasm")

File.write("spec/string.wasm", "\u0000asm\u0001\u0000\u0000\u0000\u0001\t\u0002`\u0000\u0000`\u0001\u007F\u0001\u007F\u0003\u0003\u0002\u0000\u0001\u0005\u0003\u0001\u0000\u0002\u0006E\v\u007F\u0001A\x90\x88\u0004\v\u007F\u0000A\x88\b\v\u007F\u0000A\x80\b\v\u007F\u0000A\x8C\b\v\u007F\u0000A\x90\b\v\u007F\u0000A\x90\x88\u0004\v\u007F\u0000A\x80\b\v\u007F\u0000A\x90\x88\u0004\v\u007F\u0000A\x80\x80\b\v\u007F\u0000A\u0000\v\u007F\u0000A\u0001\v\a\xB1\u0001\r\u0006memory\u0002\u0000\u0011__wasm_call_ctors\u0000\u0000\u0006string\u0000\u0001\u0004word\u0003\u0001\f__dso_handle\u0003\u0002\n__data_end\u0003\u0003\v__stack_low\u0003\u0004\f__stack_high\u0003\u0005\r__global_base\u0003\u0006\v__heap_base\u0003\a\n__heap_end\u0003\b\r__memory_base\u0003\t\f__table_base\u0003\n\nj\u0002\u0002\u0000\ve\u0001\f\u007F#\x80\x80\x80\x80\u0000!\u0001A\u0010!\u0002 \u0001 \u0002k!\u0003 \u0003 \u00006\u0002\fA\u0000!\u0004 \u0004(\u0002\x88\x88\x80\x80\u0000!\u0005 \u0003(\u0002\f!\u0006 \u0005 \u0006j!\a \a-\u0000\u0000!\bA\u0018!\t \b \tt!\n \n \tu!\v \u0003 \v6\u0002\b \u0003(\u0002\b!\f \f\u000F\v\v\u0016\u0002\u0000A\x80\b\v\u0005abcd\u0000\u0000A\x88\b\v\u0004\u0000\u0004\u0000\u0000\u0000X\u0004name\u0000\f\vstring.wasm\u0001\u001C\u0002\u0000\u0011__wasm_call_ctors\u0001\u0006string\a\u0012\u0001\u0000\u000F__stack_pointer\t\u0011\u0002\u0000\a.rodata\u0001\u0005.data\u0000\u007F\tproducers\u0001\fprocessed-by\u0001\u0005clang_18.1.2-wasi-sdk (https://github.com/llvm/llvm-project 26a1d6601d727a96f4301d0d8647b5a42760ae0c)\u0000,\u000Ftarget_features\u0002+\u000Fmutable-globals+\bsign-ext") unless File.exists?("spec/string.wasm")
