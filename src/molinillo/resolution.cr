require "./delegates/*"

module Molinillo
  class Resolver(R, S)
    class PosibilitySet(R, S)
      getter dependencies : Array(R)
      getter possibilities : Array(S)

      def initialize(@dependencies, @possibilities)
      end

      # String representation of the possibility set, for debugging
      def to_s
        "[#{possibilities.join(", ")}]"
      end

      # @return [Object] most up-to-date dependency in the possibility set
      def latest_version
        possibilities.last
      end
    end

    class Resolution(R, S)
      getter specification_provider : SpecificationProvider(R, S)
      getter resolver_ui : UI
      getter base : DependencyGraph(PosibilitySet(R, S)?, R)
      getter original_requested : Array(R)
      private getter states : Array(ResolutionState(R, S))

      # Initializes a new resolution.
      # @param [SpecificationProvider] specification_provider
      #   see {#specification_provider}
      # @param [UI] resolver_ui see {#resolver_ui}
      # @param [Array] requested see {#original_requested}
      # @param [DependencyGraph] base see {#base}
      def initialize(specification_provider, resolver_ui, requested, base)
        @specification_provider = specification_provider
        @resolver_ui = resolver_ui
        @original_requested = requested
        @base = base
        @states = Array(ResolutionState(R, S)).new
        @iteration_counter = 0
        # @parents_of = Hash.new { |h, k| h[k] = [] }
      end

      # Resolves the {#original_requested} dependencies into a full dependency
      #   graph
      # @raise [ResolverError] if successful resolution is impossible
      # @return [DependencyGraph] the dependency graph of successfully resolved
      #   dependencies
      def resolve
        start_resolution

        #   while state
        #     break if !state.requirement && state.requirements.empty?
        #     indicate_progress
        #     if state.respond_to?(:pop_possibility_state) # DependencyState
        #       debug(depth) { "Creating possibility state for #{requirement} (#{possibilities.count} remaining)" }
        #       state.pop_possibility_state.tap do |s|
        #         if s
        #           states.push(s)
        #           activated.tag(s)
        #         end
        #       end
        #     end
        #     process_topmost_state
        #   end

        #   resolve_activated_specs
        # ensure
        #   end_resolution
      end

      # Sets up the resolution process
      # @return [void]
      private def start_resolution
        @started_at = Time.local

        push_initial_state

        debug { "Starting resolution (#{@started_at})\nUser-requested dependencies: #{original_requested}" }
        resolver_ui.before_resolution
      end

      include Molinillo::Delegates::ResolutionState(R, S)
      include Molinillo::Delegates::SpecificationProvider

      # @return [RequirementState] the current state the resolution is
      #   operating upon
      def state
        states.last
      end

      # Creates and pushes the initial state for the resolution, based upon the
      # {#requested} dependencies
      # @return [void]
      def push_initial_state
        graph = DependencyGraph(PosibilitySet(R, S)?, R).new.tap do |dg|
          original_requested.each do |requested|
            vertex = dg.add_vertex(name_for(requested), nil, true)
            vertex.explicit_requirements << requested
          end
          dg.tag(:initial_state)
        end

        push_state_for_requirements(original_requested, true, graph)
      end

      # Calls the {#resolver_ui}'s {UI#debug} method
      # @param [Integer] depth the depth of the {#states} stack
      # @param [Proc] block a block that yields a {#to_s}
      # @return [void]
      def debug(depth = 0, &block)
        resolver_ui.debug(depth, &block)
      end

      # Pushes a new {DependencyState} that encapsulates both existing and new
      # requirements
      # @param [Array] new_requirements
      # @param [Boolean] requires_sort
      # @param [Object] new_activated
      # @return [void]
      def push_state_for_requirements(new_requirements, requires_sort = true, new_activated = activated)
        new_requirements = sort_dependencies(new_requirements.uniq, new_activated, conflicts) if requires_sort
        new_requirement = nil
        loop do
          new_requirement = new_requirements.shift
          break if new_requirement.nil? || states.none? { |s| s.requirement == new_requirement }
        end
        new_name = new_requirement ? name_for(new_requirement) : ""
        possibilities = possibilities_for_requirement(new_requirement)
        handle_missing_or_push_dependency_state DependencyState(R, S).new(
          new_name, new_requirements, new_activated,
          new_requirement, possibilities, depth, conflicts.dup, unused_unwind_options.dup
        )
      end

      # Checks a proposed requirement with any existing locked requirement
      # before generating an array of possibilities for it.
      # @param [Object] requirement the proposed requirement
      # @param [Object] activated
      # @return [Array] possibilities
      def possibilities_for_requirement(requirement, activated = self.activated)
        return [] of Nil unless requirement
        if locked_requirement_named(name_for(requirement))
          return locked_requirement_possibility_set(requirement, activated)
        end

        group_possibilities(search_for(requirement))
      end
    end
  end
end
