require "./spec_helper"

private def test_dependency_graph
  graph = Molinillo::DependencyGraph(String, String).new
  root = graph.add_vertex("Root", "Root", true)
  root2 = graph.add_vertex("Root2", "Root2", true)
  child = graph.add_child_vertex("Child", "Child", %w(Root), "Child")
  {graph: graph, root: root, root2: root2, child: child}
end

describe Molinillo::DependencyGraph do
  describe "in general" do
    it "returns root vertices by name" do
      data = test_dependency_graph
      data[:graph].root_vertex_named("Root").should eq(data[:root])
    end

    it "returns vertices by name" do
      data = test_dependency_graph
      data[:graph].vertex_named("Root").should eq(data[:root])
      data[:graph].vertex_named("Child").should eq(data[:child])
    end

    it "returns nil for non-existent root vertices" do
      data = test_dependency_graph
      data[:graph].root_vertex_named("missing").should be_nil
    end

    it "returns nil for non-existent vertices" do
      data = test_dependency_graph
      data[:graph].vertex_named("missing").should be_nil
    end
  end
end
