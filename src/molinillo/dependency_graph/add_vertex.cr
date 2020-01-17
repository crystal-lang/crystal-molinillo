require "./action"

class Molinillo::DependencyGraph
  class AddVertex(P, R) < Action
    getter name : String
    getter payload : P
    getter root : Bool

    @existing_payload : P?
    @existing_root : Bool?

    def initialize(@name, @payload : P, @root)
    end

    def self.action_name
      :add_vertex
    end

    def up(graph)
      if existing = graph.vertices[name]?
        @existing_payload = existing.payload
        @existing_root = existing.root
      end
      vertex = existing || Vertex(P, R).new(name, payload)
      graph.vertices[vertex.name] = vertex
      vertex.payload ||= payload
      vertex.root ||= root
      vertex
    end
  end
end
