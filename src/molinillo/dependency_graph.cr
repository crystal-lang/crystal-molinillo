class Molinillo::DependencyGraph(P, R)
end

require "./dependency_graph/log"
require "./dependency_graph/vertex"

class Molinillo::DependencyGraph(P, R)
  getter log : Log(P, R)
  getter vertices : Hash(String, Vertex(P, R))

  # A directed edge of a {DependencyGraph}
  # @attr [Vertex] origin The origin of the directed edge
  # @attr [Vertex] destination The destination of the directed edge
  # @attr [Object] requirement The requirement the directed edge represents
  record Edge(P, R), origin : Vertex(P, R), destination : Vertex(P, R), requirement : R

  def initialize
    @vertices = {} of String => Vertex(P, R)
    @log = Log(P, R).new
  end

  # Tags the current state of the dependency as the given tag
  # @param  [Object] tag an opaque tag for the current state of the graph
  # @return [Void]
  def tag(tag : Reference)
    log.tag(self, tag)
  end

  # Rewinds the graph to the state tagged as `tag`
  # @param  [Object] tag the tag to rewind to
  # @return [Void]
  def rewind_to(tag)
    log.rewind_to(self, tag)
  end

  def to_dot
    dot_vertices = [] of String
    dot_edges = [] of String
    vertices.each do |n, v|
      dot_vertices << "  #{n} [label=\"{#{n}|#{v.payload}}\"]"
      v.outgoing_edges.each do |e|
        label = e.requirement
        dot_edges << "  #{e.origin.name} -> #{e.destination.name} [label=#{label.to_s.dump}]"
      end
    end

    dot_vertices.uniq!
    dot_vertices.sort!
    dot_edges.uniq!
    dot_edges.sort!

    dot = dot_vertices.unshift("digraph G {").push("") + dot_edges.push("}")
    dot.join("\n")
  end

  def ==(other)
    super || begin
      return false unless vertices.keys.to_set == other.vertices.keys.to_set
      vertices.each do |name, vertex|
        other_vertex = other.vertex_named(name)
        return false unless other_vertex
        return false unless vertex.payload == other_vertex.payload
        return false unless other_vertex.successors.to_set == vertex.successors.to_set
      end
      true
    end
  end

  # @param [String] name
  # @param [Object] payload
  # @param [Array<String>] parent_names
  # @param [Object] requirement the requirement that is requiring the child
  # @return [void]
  def add_child_vertex(name : String, payload : P, parent_names : Array(String?), requirement : R)
    root = !(parent_names.delete(nil) || true)
    vertex = add_vertex(name, payload, root)
    # vertex.explicit_requirements << requirement if root
    parent_names.each do |parent_name|
      if parent_vertex = vertex_named(parent_name)
        add_edge(parent_vertex, vertex, requirement)
      end
    end
    vertex
  end

  # Adds a vertex with the given name, or updates the existing one.
  # @param [String] name
  # @param [Object] payload
  # @return [Vertex] the vertex that was added to `self`
  def add_vertex(name : String, payload : P, root : Bool = false)
    log.add_vertex(self, name, payload, root)
  end

  # @param [String] name
  # @return [Vertex,nil] the vertex with the given name
  def vertex_named(name) : Vertex(P, R)?
    vertices[name]?
  end

  # @param [String] name
  # @return [Vertex,nil] the vertex with the given name
  def vertex_named!(name) : Vertex(P, R)
    vertices[name]
  end

  # @param [String] name
  # @return [Vertex,nil] the root vertex with the given name
  def root_vertex_named(name) : Vertex(P, R)?
    vertex = vertex_named(name)
    vertex if vertex && vertex.root
  end

  # Adds a new {Edge} to the dependency graph
  # @param [Vertex] origin
  # @param [Vertex] destination
  # @param [Object] requirement the requirement that this edge represents
  # @return [Edge] the added edge
  def add_edge(origin : Vertex(P, R), destination : Vertex(P, R), requirement : R)
    if destination.path_to?(origin)
      # raise CircularDependencyError.new(path(destination, origin))
      raise "tbd"
    end
    add_edge_no_circular(origin, destination, requirement)
  end

  # Adds a new {Edge} to the dependency graph without checking for
  # circularity.
  # @param (see #add_edge)
  # @return (see #add_edge)
  private def add_edge_no_circular(origin, destination, requirement)
    log.add_edge_no_circular(self, origin.name, destination.name, requirement)
  end
end
