require "json"

module CrystalWamr
  class WamrConfig
    include JSON::Serializable

    property file : String
    property func : Array(Func)
  end

  class Func
    include JSON::Serializable

    property name : String
    property input : Array(Input)
  end

  class Input
    include JSON::Serializable

    property argv : Argv
  end

  class Argv
    include JSON::Serializable

    property int : Int32?
    property var : String?
    property sys : Sys?
  end

  class Sys
    include JSON::Serializable

    property name : String
    property argv : Array(Int32)
  end
end
