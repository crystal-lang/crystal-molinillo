require "./action"

class Molinillo::DependencyGraph
  class AddEdgeNoCircular(R) < Action
    getter origin : String
    getter destination : String
    getter requirement : R

    def initialize(@origin, @destination, @requirement : R)
    end

    def up(graph)
      edge = make_edge(graph)
      edge.origin.outgoing_edges << edge
      edge.destination.incoming_edges << edge
      edge
    end

    # @param  [DependencyGraph] graph the graph to find vertices from
    # @return [Edge] The edge this action adds
    def make_edge(graph)
      Edge.new(graph.vertex_named!(origin), graph.vertex_named!(destination), requirement)
    end
  end
end
