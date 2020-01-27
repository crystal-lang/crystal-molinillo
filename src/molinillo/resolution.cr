require "./delegates/*"

module Molinillo
  class Resolver(R, S)
    class Resolution(R, S)
      class PossibilitySet(R, S)
        getter dependencies : Array(R)
        getter possibilities : Array(S)

        def initialize(@dependencies, @possibilities)
        end

        # String representation of the possibility set, for debugging
        def to_s(io)
          io << "[#{possibilities.join(", ")}]"
        end

        # @return [Object] most up-to-date dependency in the possibility set
        def latest_version
          possibilities.last
        end
      end

      getter specification_provider : SpecificationProvider(R, S)
      getter resolver_ui : UI
      getter base : DependencyGraph(R, R)
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
        @parents_of = Hash(R, Array(Int32)).new { |h, k| h[k] = [] of Int32 }
      end

      # Resolves the {#original_requested} dependencies into a full dependency
      #   graph
      # @raise [ResolverError] if successful resolution is impossible
      # @return [DependencyGraph] the dependency graph of successfully resolved
      #   dependencies
      def resolve
        start_resolution

        while st = state
          break if !st.requirement && st.requirements.empty?
          # indicate_progress
          if st.is_a?(DependencyState) # DependencyState
            debug(depth) { "Creating possibility state for #{requirement} (#{possibilities.size} remaining)" }
            st.pop_possibility_state.tap do |s|
              if s
                states.push(s)
                activated.tag(s)
              end
            end
          end
          process_topmost_state
        end

        resolve_activated_specs
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

      def resolve_activated_specs
        final = DependencyGraph(S, S).new
        # puts
        # puts activated.to_dot
        activated.vertices.each do |_, vertex|
          next unless payload = vertex.payload

          latest_version = payload.possibilities.reverse_each.find do |possibility|
            vertex.requirements.all? { |req| requirement_satisfied_by?(req, activated, possibility) }
          end

          final.add_vertex(vertex.name, latest_version.not_nil!, vertex.root)
        end
        final
      end

      include Molinillo::Delegates::ResolutionState(R, S)
      include Molinillo::Delegates::SpecificationProvider

      # Processes the topmost available {RequirementState} on the stack
      # @return [void]
      def process_topmost_state
        if possibility
          attempt_to_activate
        else
          raise "tbd @ process_topmost_state"
          # create_conflict
          # unwind_for_conflict
        end
        # rescue underlying_error : CircularDependencyError
        #   create_conflict(underlying_error)
        #   unwind_for_conflict
      end

      # @return [Object] the current possibility that the resolution is trying
      #   to activate
      def possibility
        possibilities.last
      end

      # @return [RequirementState] the current state the resolution is
      #   operating upon
      def state
        states.last?
      end

      # Creates and pushes the initial state for the resolution, based upon the
      # {#requested} dependencies
      # @return [void]
      def push_initial_state
        graph = DependencyGraph(PossibilitySet(R, S)?, R).new.tap do |dg|
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
      def debug(depth = 0)
        resolver_ui.debug(depth) { yield }
      end

      # Attempts to activate the current {#possibility}
      # @return [void]
      def attempt_to_activate
        debug(depth) { "Attempting to activate " + possibility.to_s }
        existing_vertex = activated.vertex_named!(name)
        if existing_vertex.payload
          debug(depth) { "Found existing spec (#{existing_vertex.payload})" }
          attempt_to_filter_existing_spec(existing_vertex)
        else
          latest = possibility.latest_version
          possibility.possibilities.select! do |possibility|
            requirement_satisfied_by?(requirement.not_nil!, activated.not_nil!, possibility)
          end
          if possibility.latest_version.nil?
            # ensure there's a possibility for better error messages
            possibility.possibilities << latest if latest
            # create_conflict
            # unwind_for_conflict
            raise "tbd @ attempt_to_activate"
          else
            activate_new_spec
          end
        end
      end

      # Attempts to update the existing vertex's `PossibilitySet` with a filtered version
      # @return [void]
      def attempt_to_filter_existing_spec(vertex)
        filtered_set = filtered_possibility_set(vertex)
        if !filtered_set.possibilities.empty?
          activated.set_payload(name.not_nil!, filtered_set)
          new_requirements = requirements.dup
          push_state_for_requirements(new_requirements, false)
        else
          # create_conflict
          debug(depth) { "Unsatisfied by existing spec (#{vertex.payload})" }
          # unwind_for_conflict
          raise "tbd @ attempt_to_filter_existing_spec"
        end
      end

      # Generates a filtered version of the existing vertex's `PossibilitySet` using the
      # current state's `requirement`
      # @param [Object] vertex existing vertex
      # @return [PossibilitySet] filtered possibility set
      def filtered_possibility_set(vertex)
        PossibilitySet(R, S).new(vertex.payload.not_nil!.dependencies, vertex.payload.not_nil!.possibilities & possibility.possibilities)
      end

      # @param [String] requirement_name the spec name to search for
      # @return [Object] the locked spec named `requirement_name`, if one
      #   is found on {#base}
      def locked_requirement_named(requirement_name)
        vertex = base.vertex_named(requirement_name)
        vertex && vertex.payload
      end

      # Add the current {#possibility} to the dependency graph of the current
      # {#state}
      # @return [void]
      def activate_new_spec
        conflicts.delete(name)
        debug(depth) { "Activated #{name} at #{possibility}" }
        activated.set_payload(name.not_nil!, possibility)
        require_nested_dependencies_for(possibility)
      end

      # Requires the dependencies that the recently activated spec has
      # @param [Object] possibility_set the PossibilitySet that has just been
      #   activated
      # @return [void]
      def require_nested_dependencies_for(possibility_set)
        nested_dependencies = dependencies_for(possibility_set.latest_version)
        debug(depth) { "Requiring nested dependencies (#{nested_dependencies.join(", ")})" }
        nested_dependencies.each do |d|
          activated.add_child_vertex(name_for(d), nil, [name_for(possibility_set.latest_version)], d)
          parent_index = states.size - 1
          parents = @parents_of[d]
          parents << parent_index if parents.empty?
        end

        push_state_for_requirements(requirements + nested_dependencies, !nested_dependencies.empty?)
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
          new_requirement = new_requirements.shift?
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
        return [] of PossibilitySet(R, S) unless requirement
        if locked_requirement_named(name_for(requirement))
          return locked_requirement_possibility_set(requirement, activated)
        end

        group_possibilities(search_for(requirement))
      end

      # @param [Object] requirement the proposed requirement
      # @param [Object] activated
      # @return [Array] possibility set containing only the locked requirement, if any
      def locked_requirement_possibility_set(requirement, activated = self.activated)
        all_possibilities = search_for(requirement)
        locked_requirement = locked_requirement_named(name_for(requirement)).not_nil!

        # Longwinded way to build a possibilities array with either the locked
        # requirement or nothing in it. Required, since the API for
        # locked_requirement isn't guaranteed.
        locked_possibilities = all_possibilities.select do |possibility|
          requirement_satisfied_by?(locked_requirement, activated, possibility)
        end

        group_possibilities(locked_possibilities)
      end

      # Build an array of PossibilitySets, with each element representing a group of
      # dependency versions that all have the same sub-dependency version constraints
      # and are contiguous.
      # @param [Array] possibilities an array of possibilities
      # @return [Array<PossibilitySet>] an array of possibility sets
      def group_possibilities(possibilities)
        possibility_sets = [] of PossibilitySet(R, S)
        current_possibility_set = nil

        possibilities.reverse_each do |possibility|
          dependencies = dependencies_for(possibility)
          if current_possibility_set && current_possibility_set.dependencies == dependencies
            current_possibility_set.possibilities.unshift(possibility)
          else
            possibility_sets.unshift(PossibilitySet(R, S).new(dependencies, [possibility]))
            current_possibility_set = possibility_sets.first
          end
        end

        possibility_sets
      end

      # Pushes a new {DependencyState}.
      # If the {#specification_provider} says to
      # {SpecificationProvider#allow_missing?} that particular requirement, and
      # there are no possibilities for that requirement, then `state` is not
      # pushed, and the vertex in {#activated} is removed, and we continue
      # resolving the remaining requirements.
      # @param [DependencyState] state
      # @return [void]
      def handle_missing_or_push_dependency_state(state)
        if (req = state.requirement) && state.possibilities.empty? && allow_missing?(req)
          state.activated.detach_vertex_named(state.name.not_nil!)
          push_state_for_requirements(state.requirements.dup, false, state.activated)
        else
          states.push(state).tap { activated.tag(state) }
        end
      end
    end
  end
end
