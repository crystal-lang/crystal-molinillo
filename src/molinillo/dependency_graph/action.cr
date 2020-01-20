abstract class Molinillo::DependencyGraph::Action(P, R)
  property previous : Action(P, R)?
  property next : Action(P, R)?

  def self.action_name : Symbol
    raise "abstract"
  end

  # Performs the action on the given graph.
  # @param  [DependencyGraph] graph the graph to perform the action on.
  # @return [Void]
  abstract def up(graph : DependencyGraph(P, R))

  # Reverses the action on the given graph.
  # @param  [DependencyGraph] graph the graph to reverse the action on.
  # @return [Void]
  abstract def down(graph : DependencyGraph(P, R))
end
