require "./spec_helper"

module Molinillo
  FIXTURE_CASE_DIR = FIXTURE_DIR / "case"

  class TestCase
    getter fixture : Fixture
    getter name : String
    @index : SpecificationProvider(Nil, Nil, Nil)?
    @result : DependencyGraph(TestSpecification?, TestSpecification?)?
    @@all : Array(TestCase)?

    def self.from_fixture(fixture_path)
      fixture = File.open(fixture_path) { |f| Fixture.from_json(f) }
      new(fixture)
    end

    def initialize(@fixture)
      @name = fixture.name
    end

    def index
      @index ||= TestIndex.from_fixture(@fixture.index || "awesome")
    end

    def requested
      # @requested ||= @fixture['requested'].map do |(name, reqs)|
      #   Gem::Dependency.new name.delete("\x01"), reqs.split(',').map(&:chomp)
      # end
      @fixture.requested
    end

    def add_dependencies_to_graph(graph, parent, hash, all_parents = Set(DependencyGraph::Vertex(TestSpecification?, TestSpecification?)).new)
      name = hash.name
      version = hash.version # Gem::Version.new(hash['version'])
      dependency = index.specs[name].find { |s| s.version == version }
      vertex = if parent
                 graph.add_vertex(name, dependency).tap do |v|
                   graph.add_edge(parent, v, dependency)
                 end
               else
                 graph.add_vertex(name, dependency, true)
               end
      return unless all_parents.add?(vertex)
      hash.dependencies.each do |dep|
        add_dependencies_to_graph(graph, vertex, dep, all_parents)
      end
    end

    def result
      @result ||= @fixture.resolved.reduce(DependencyGraph(TestSpecification?, TestSpecification?).new) do |graph, r|
        graph.tap do |g|
          add_dependencies_to_graph(g, nil, r)
        end
      end
    end

    def base
      DependencyGraph(Nil, Nil).new
    end

    def self.all
      @@all ||= Dir.glob(FIXTURE_CASE_DIR.to_s + "**/*.json").map { |fixture| TestCase.from_fixture(fixture) }
    end

    def resolve(index_class)
      index = index_class.new(self.index.specs)
      resolver = Resolver(Nil, Nil, Nil).new(index, TestUI.new)
      resolver.resolve(requested, base)
    end

    def run(index_class)
      it name do
        # skip 'does not yet reliably pass' if test_case.ignore?(index_class)
        if fixture.conflicts.any?
        else
          result = resolve(index_class)

          result.should eq(self.result)
        end
      end
    end
  end

  describe Resolver do
    describe "dependency resolution" do
      describe "with the TestIndex index" do
        TestCase.all.each &.run(TestIndex)
      end
    end
  end
end

# it "list all cases" do
#   pp Molinillo::TestCase.all
# end
