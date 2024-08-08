require "./crystal_wamr_config"

# TODO: Write documentation for `CrystalWamr`
module CrystalWamr
  VERSION = "0.1.0"

  class WASM
    @[Link("iwasm")]
    lib LibWasm
      type WASMModuleCommon = Void
      type WASMModuleInstanceCommon = Void
      type WASMExecEnv = Void
      type WASMFunctionInstanceCommon = Void

      fun wasm_runtime_init : Bool
      fun wasm_runtime_load(LibC::Char*, LibC::UInt, LibC::Char*, LibC::UInt) : WASMModuleCommon*
      fun wasm_runtime_instantiate(WASMModuleCommon*, LibC::UInt, LibC::UInt, LibC::Char*, LibC::UInt) : WASMModuleInstanceCommon*
      fun wasm_runtime_lookup_function(WASMModuleInstanceCommon*, LibC::Char*, LibC::Char*) : WASMFunctionInstanceCommon*
      fun wasm_runtime_create_exec_env(WASMModuleInstanceCommon*, LibC::UInt) : WASMExecEnv*
      fun wasm_runtime_call_wasm(WASMExecEnv*, WASMFunctionInstanceCommon*, LibC::UInt, LibC::Int*) : Bool
      fun wasm_runtime_get_exception(WASMModuleInstanceCommon*) : LibC::Char*
      fun wasm_runtime_destroy_exec_env(WASMExecEnv*)
      fun wasm_runtime_deinstantiate(WASMModuleInstanceCommon*)
      fun wasm_runtime_unload(WASMModuleCommon*)
      fun wasm_runtime_destroy : Nil
    end

    @hash = Hash(String, Int32).new

    def add_to_hash(name, value)
      @hash[name] = value
    end

    def return_hash
      return @hash
    end

    macro return_string(file, func, max_word_length = 16)
        string = ""
      {% for i in (0..max_word_length) %}
            char = wasm.exec_once({{file}}, {{func}}, [{{i}}])
            string += char.not_nil!.unsafe_chr
      {% end %}
        is_last_char_nil = string.byte_index '\u0000'

        if is_last_char_nil == nil
        p string
        else
        last = is_last_char_nil
        last_char = last.not_nil! - 1
        p string[0..last_char]
        end
    end

    def function_args(value : Int32, variable : String?, sys, functions, index, output, path)
      functions[index] << value
    end

    def function_args(value : Nil, variable : String?, sys, functions, index, output, path)
    end

    def function_args(value : Nil, variable : String, sys : CrystalWamr::Sys, functions, index, output, path)
      x = [] of Int32
      if variable == "$URL"
        if /\d*/.match(path).to_s != ""
          a = path.scan /\d*/
          a.each do |v|
            x << v.to_s.to_i unless v.to_s == ""
          end
        else
          x = [0, 0, 0, 0, 0]
        end
      end
      native_functions sys, functions, index, x
    end

    def function_args(value : Nil, variable : String, sys : Nil, functions, index, output, path)
      output[index] = variable
    end

    def function_args(value : Nil, variable : String?, sys : Nil, functions, index, output, path)
    end

    def exec_json(config : CrystalWamr::WamrConfig, path : String, functions = Hash(String, Array(Int32)).new, output = Hash(String, String).new)
      config.func.map do |i|
        functions[i.name] = [] of Int32
        i.input.map { |x| function_args(x.argv.int, x.argv.var, x.argv.sys, functions, i.name, output, path) }
      end
      exec(File.read(config.file), functions, output)
    end

    def exec_once(wasm_file : String, function_name : String, argv : Array(Int32))
      # initialize the wasm runtime by default configurations
      LibWasm.wasm_runtime_init
      # read WASM file into a memory buffer
      # buffer = LibWasm.read_wasm_binary_to_buffer(wasm_file, wasm_file.bytesize);
      # parse the WASM file from buffer and create a WASM module
      mymodule = LibWasm.wasm_runtime_load(wasm_file, wasm_file.size, "", 0)
      # create an instance of the WASM module (WASM linear memory is ready)
      module_inst = LibWasm.wasm_runtime_instantiate(mymodule, 8092, 8092, "", 0)
      # lookup a WASM function by its name
      # The function signature can NULL here
      func = LibWasm.wasm_runtime_lookup_function(module_inst, function_name, "")
      # creat an execution environment to execute the WASM functions
      exec_env = LibWasm.wasm_runtime_create_exec_env(module_inst, 8092)
      # call the WASM function
      if LibWasm.wasm_runtime_call_wasm(exec_env, func, argv.size, argv)
        # the return value is stored in argv[0]
        # argv = array of arguments
        return argv[0]
      else
        LibWasm.wasm_runtime_get_exception(module_inst)
        # exception is thrown if call fails
      end

      LibWasm.wasm_runtime_destroy_exec_env(exec_env)
      LibWasm.wasm_runtime_deinstantiate(module_inst)
      LibWasm.wasm_runtime_unload(mymodule)
      LibWasm.wasm_runtime_destroy
    end

    def exec(wasm_file : String, functions = Hash(String, Array(Int32)).new, output = Hash(String, String).new)
      LibWasm.wasm_runtime_init
      mymodule = LibWasm.wasm_runtime_load(wasm_file, wasm_file.size, "", 0)
      module_inst = LibWasm.wasm_runtime_instantiate(mymodule, 8092, 8092, "", 0)

      functions.each do |x, argv|
        if output.has_key? x
          a = output[x]
          argv << @hash[a]
        end

        function = LibWasm.wasm_runtime_lookup_function(module_inst, x, "")

        exec_env = LibWasm.wasm_runtime_create_exec_env(module_inst, 8092)
        if LibWasm.wasm_runtime_call_wasm(exec_env, function, argv.size, argv)
          add_to_hash(x, argv[0])
        else
          LibWasm.wasm_runtime_get_exception(module_inst)
        end
        functions.delete(x)
      end
      exec_env = LibWasm.wasm_runtime_create_exec_env(module_inst, 8092)

      LibWasm.wasm_runtime_destroy_exec_env(exec_env)
      LibWasm.wasm_runtime_deinstantiate(module_inst)
      LibWasm.wasm_runtime_unload(mymodule)
      LibWasm.wasm_runtime_destroy
    end
  end
end
