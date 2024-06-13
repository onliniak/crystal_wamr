module CrystalWamr
  class WASM
    @[Link("iwasm")]
    lib LibWasm
      struct WASMModuleCommon
        buffer : LibC::Char*
        binary_file : LibC::UInt
        io_error : LibC::Char*
        io_error_bytesize : LibC::UInt
      end

      struct WASMModuleInstanceCommon
        mymodule : WASMModuleCommon*
        stack_size : LibC::UInt
        heap_size : LibC::UInt
        io_error : LibC::Char*
        io_error_bytesize : LibC::UInt
      end

      struct WASMExecEnv
        module_inst : WASMModuleInstanceCommon*
        stack_size : LibC::UInt
      end

      struct WASMFunctionInstanceCommon
        module_inst : WASMModuleInstanceCommon*
        func_name : LibC::Char*
        func_signature : LibC::Char*
      end

      fun wasm_runtime_init : Bool
      # fun read_wasm_binary_to_buffer(LibC::Char*, Int32) : LibC::Char*
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

    # Example:
    # ```
    # wasm = CrystalWamr::WASM.new
    # wasm.exec(*wasm_file* = absolute path to file, *function_name*, *argv* = array of arguments, *msg* = print custom message, *io_error*, *stack_size*, *heap_size*)
    # ```
    def exec(wasm_file : String, function_name : String, argv : Array(Int32), msg : String = "#{function_name} function return:", io_error = IO::Memory.new, stack_size = 8092, heap_size = 8092)
      # initialize the wasm runtime by default configurations
      LibWasm.wasm_runtime_init
      # read WASM file into a memory buffer
      # buffer = LibWasm.read_wasm_binary_to_buffer(wasm_file, wasm_file.bytesize);
      # parse the WASM file from buffer and create a WASM module
      mymodule = LibWasm.wasm_runtime_load(wasm_file, wasm_file.size, io_error.to_s, io_error.bytesize)
      # create an instance of the WASM module (WASM linear memory is ready)
      module_inst = LibWasm.wasm_runtime_instantiate(mymodule, stack_size, heap_size, io_error.to_s, io_error.bytesize)
      # lookup a WASM function by its name
      # The function signature can NULL here
      func = LibWasm.wasm_runtime_lookup_function(module_inst, function_name, "(i32i32)")
      # creat an execution environment to execute the WASM functions
      exec_env = LibWasm.wasm_runtime_create_exec_env(module_inst, stack_size)
      # call the WASM function
      if LibWasm.wasm_runtime_call_wasm(exec_env, func, argv.size, argv)
        # the return value is stored in argv[0]
        # argv = array of arguments
        return "#{msg} #{argv[0]}"
      else
        LibWasm.wasm_runtime_get_exception(module_inst)
        # exception is thrown if call fails
      end

      LibWasm.wasm_runtime_destroy_exec_env(exec_env)
      LibWasm.wasm_runtime_deinstantiate(module_inst)
      LibWasm.wasm_runtime_unload(mymodule)
      LibWasm.wasm_runtime_destroy
    end
  end
end
