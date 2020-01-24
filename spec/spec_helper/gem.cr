module Gem
  class Dependency
    property name : String
    property requirement : Requirement

    def initialize(@name, requirements : Array(String))
      @requirement = Requirement.new(requirements)
    end
  end

  class Requirement
    property requirements : Array(String)

    def initialize(@requirements)
    end

    def satisfied_by?(version : String)
      true
    end
  end
end
