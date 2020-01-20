require "./action"

class Molinillo::DependencyGraph
  class Tag(P, R) < Action(P, R)
    getter tag : UInt64

    def up(graph)
    end

    def down(graph)
    end

    def initialize(@tag)
    end
  end
end
