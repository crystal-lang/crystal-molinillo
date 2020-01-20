require "json"

module Molinillo
  class TestSpecification
    JSON.mapping(
      name: String,
      version: String,
      dependencies: {type: Hash(String, String), converter: DepConverter}
    )
  end

  module DepConverter
    def self.from_json(parser)
      if parser.kind.begin_object?
        Hash(String, String).new(parser)
      else
        Hash(String, String).new.tap do |deps|
          parser.read_array do
            parser.read_begin_array
            key = parser.read_string
            value = parser.read_string
            parser.read_end_array
            deps[key] = value
          end
        end
      end
    end
  end
end
