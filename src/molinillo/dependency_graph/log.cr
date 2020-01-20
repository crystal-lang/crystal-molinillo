require "./add_vertex"
require "./add_edge_no_circular"

class Molinillo::DependencyGraph::Log(P, R)
  @current_action : Action(P, R)?
  @first_action : Action(P, R)?

  def tag(graph, tag)
    push_action(graph, Tag(P, R).new(tag.object_id))
  end

  def add_vertex(graph, name : String, payload : P, root)
    push_action(graph, AddVertex(P, R).new(name, payload, root))
  end

  def add_edge_no_circular(graph, origin, destination, requirement)
    push_action(graph, AddEdgeNoCircular(P, R).new(origin, destination, requirement))
  end

  # Pops the most recent action from the log and undoes the action
  # @param [DependencyGraph] graph
  # @return [Action] the action that was popped off the log
  def pop!(graph)
    return unless action = @current_action
    unless @current_action = action.previous
      @first_action = nil
    end
    action.down(graph)
    action
  end

  # Enumerates each action in the log
  # @yield [Action]
  def each
    action = @first_action
    loop do
      break unless action
      yield action
      action = action.next
    end
    self
  end

  def rewind_to(graph, tag)
    loop do
      action = pop!(graph)
      raise "No tag #{tag.inspect} found" unless action
      break if action.is_a?(Tag(P, R)) && action.tag == tag.object_id
    end
  end

  # Adds the given action to the log, running the action
  # @param [DependencyGraph] graph
  # @param [Action] action
  # @return The value returned by `action.up`
  private def push_action(graph, action)
    action.previous = @current_action
    if current_action = @current_action
      current_action.next = action
    end
    @current_action = action
    @first_action ||= action
    action.up(graph)
  end
end
