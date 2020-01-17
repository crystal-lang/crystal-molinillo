abstract class Molinillo::DependencyGraph::Action
  property previous : Action?
  property next : Action?

  def self.action_name : Symbol
    raise "abstract"
  end

  abstract def up(graph)
end
