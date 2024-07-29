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

    def function_args(value : Int32, variable : String?, sys, functions, index, output, path)
      functions[index] << value
    end

    def function_args(value : Nil, variable : String?, sys, functions, index, output, path)
    end

    def function_args(value : Nil, variable : String, sys : CrystalWamr::Sys, functions, index, output, path)
      x = 0
      if variable == "$URL"
        a = path =~ /^(0|[1-9][0-9]*)$/
        if a == 0
          x = path
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
        # output i.output, output, i.name
      end
      exec(File.read(config.file), functions, output)
    end

    @hash = Hash(String, Int32).new

    def add_to_hash(name, value)
      @hash[name] = value
    end

    def return_hash
      return @hash
    end

    # Example:
    # ```
    # wasm = CrystalWamr::WASM.new
    # wasm.exec(*wasm_file* = absolute path to file, *function_name*, *argv* = array of arguments, *msg* = print custom message, *io_error*, *stack_size*, *heap_size*)
    # ```
    def exec(wasm_file : String, functions = Hash(String, Array(Int32)).new, output = Hash(String, String).new)
      # initialize the wasm runtime by default configurations
      LibWasm.wasm_runtime_init
      # read WASM file into a memory buffer
      # parse the WASM file from buffer and create a WASM module
      mymodule = LibWasm.wasm_runtime_load(wasm_file, wasm_file.size, "", 0)
      # create an instance of the WASM module (WASM linear memory is ready)
      module_inst = LibWasm.wasm_runtime_instantiate(mymodule, 8092, 8092, "", 0)

      functions.each do |x, argv|
        if output.has_key? x
          a = output[x]
          argv << @hash[a]
        end

        # lookup a WASM function by its name
        # The function signature can NULL here
        function = LibWasm.wasm_runtime_lookup_function(module_inst, x, "(NULL)")

        # creat an execution environment to execute the WASM functions
        exec_env = LibWasm.wasm_runtime_create_exec_env(module_inst, 8092)
        # call the WASM function
        if LibWasm.wasm_runtime_call_wasm(exec_env, function, argv.size, argv)
          # the return value is stored in argv[0]
          # argv = array of arguments
          add_to_hash(x, argv[0])
        else
          LibWasm.wasm_runtime_get_exception(module_inst)
          # exception is thrown if call fails
        end
        functions.delete(x)
      end
      # creat an execution environment to execute the WASM functions
      exec_env = LibWasm.wasm_runtime_create_exec_env(module_inst, 8092)

      LibWasm.wasm_runtime_destroy_exec_env(exec_env)
      LibWasm.wasm_runtime_deinstantiate(module_inst)
      LibWasm.wasm_runtime_unload(mymodule)
      LibWasm.wasm_runtime_destroy
    end
  end
end
