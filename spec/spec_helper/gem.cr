module Gem
  class Dependency
    property name : String
    property requirements : Array(String)

    def initialize(@name, @requirements)
    end
  end
end
