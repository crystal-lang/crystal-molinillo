require "json"

module Molinillo
  class TestSpecification
    JSON.mapping(
      name: String,
      version: String,
      dependencies: {type: Array(Gem::Dependency | TestSpecification), converter: DepConverter}
    )

    def to_s(io)
      io << "#{name} (#{version})"
    end

    def prerelease?
      Shards::Versions.prerelease?(version)
    end
  end

  module DepConverter
    def self.from_json(parser)
      if parser.kind.begin_object?
        deps = Hash(String, String).new(parser)
      else
        deps = Hash(String, String).new

        parser.read_array do
          parser.read_begin_array
          key = parser.read_string
          value = parser.read_string
          parser.read_end_array

          deps[key] = value
        end
      end

      deps.map do |name, requirement|
        requirements = requirement.split(',').map!(&.chomp)
        Gem::Dependency.new(name, requirements).as(Gem::Dependency | TestSpecification)
      end
    end
  end
end
