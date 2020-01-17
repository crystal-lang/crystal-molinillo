require "./add_vertex"
require "./add_edge_no_circular"

class Molinillo::DependencyGraph::Log(P, R)
  @current_action : Action?
  @first_action : Action?

  def add_vertex(graph, name, payload, root)
    push_action(graph, AddVertex(P, R).new(name, payload, root))
  end

  def add_edge_no_circular(graph, origin, destination, requirement)
    push_action(graph, AddEdgeNoCircular.new(origin, destination, requirement))
  end

  # Adds the given action to the log, running the action
  # @param [DependencyGraph] graph
  # @param [Action] action
  # @return The value returned by `action.up`
  def push_action(graph, action)
    action.previous = @current_action
    if current_action = @current_action
      current_action.next = action
    end
    @current_action = action
    @first_action ||= action
    action.up(graph)
  end
end
