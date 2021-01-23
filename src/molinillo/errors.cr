require "./delegates/specification_provider"

module Molinillo
  # An error that occurred during the resolution process
  class ResolverError < Exception; end

  # An error caused by searching for a dependency that is completely unknown,
  # i.e. has no versions available whatsoever.
  class NoSuchDependencyError < ResolverError
    # @return [Object] the dependency that could not be found
    getter dependency : String

    # @return [Array<Object>] the specifications that depended upon {#dependency}
    getter required_by : Array(String)

    # Initializes a new error with the given missing dependency.
    # @param [Object] dependency @see {#dependency}
    # @param [Array<Object>] required_by @see {#required_by}
    def initialize(dependency, required_by = [] of S)
      @dependency = dependency
      @required_by = required_by.uniq
      super
    end

    # The error message for the missing dependency, including the specifications
    # that had this dependency.
    def message
      sources = required_by.join(" and ") { |r| "`#{r}`" }
      message = "Unable to find a specification for `#{dependency}`"
      message += " depended upon by #{sources}" unless sources.empty?
      message
    end
  end

  # An error caused by attempting to fulfil a dependency that was circular
  #
  # @note This exception will be thrown iff a {Vertex} is added to a
  #   {DependencyGraph} that has a {DependencyGraph::Vertex#path_to?} an
  #   existing {DependencyGraph::Vertex}
  class CircularDependencyError(P, R) < ResolverError
    # [Set<Object>] the dependencies responsible for causing the error
    getter vertices : Array(DependencyGraph::Vertex(P, R))

    # Initializes a new error with the given circular vertices.
    # @param [Array<DependencyGraph::Vertex>] vertices the vertices in the dependency
    #   that caused the error
    def initialize(@vertices)
      super "There is a circular dependency between #{vertices.join(" and ", &.name)}"
      # @dependencies = vertices.map { |vertex| vertex.payload.possibilities.last }.to_set
    end
  end

  # An error caused by conflicts in version
  class VersionConflict(R, S) < ResolverError
    # @return [{String => Resolution::Conflict}] the conflicts that caused
    #   resolution to fail
    getter conflicts : Hash(String, Resolver::Resolution::Conflict(R, S))

    # @return [SpecificationProvider] the specification provider used during
    #   resolution
    getter specification_provider : SpecificationProvider(R, S)

    # Initializes a new error with the given version conflicts.
    # @param [{String => Resolution::Conflict}] conflicts see {#conflicts}
    # @param [SpecificationProvider] specification_provider see {#specification_provider}
    def initialize(conflicts, specification_provider)
      pairs = [] of {R, S | String}
      conflicts.values.flatten.flat_map(&.requirements).each do |conflicting|
        conflicting.each do |source, conflict_requirements|
          conflict_requirements.each do |c|
            pairs << {c, source}
          end
        end
      end

      super "Unable to satisfy the following requirements:\n\n" \
            "#{pairs.join('\n') { |r, d| "- `#{r}` required by `#{d}`" }}"

      @conflicts = conflicts
      @specification_provider = specification_provider
    end

    include Delegates::SpecificationProvider

    # @return [String] An error message that includes requirement trees,
    #   which is much more detailed & customizable than the default message
    # @param [Hash] opts the options to create a message with.
    # @option opts [String] :solver_name The user-facing name of the solver
    # @option opts [String] :possibility_type The generic name of a possibility
    # @option opts [Proc] :reduce_trees A proc that reduced the list of requirement trees
    # @option opts [Proc] :printable_requirement A proc that pretty-prints requirements
    # @option opts [Proc] :additional_message_for_conflict A proc that appends additional
    #   messages for each conflict
    # @option opts [Proc] :version_for_spec A proc that returns the version number for a
    #   possibility
    def message_with_trees(opts = {} of Symbol => String)
      solver_name = opts.delete(:solver_name) { self.class.name.split("::").first }
      possibility_type = opts.delete(:possibility_type) { "possibility named" }
      reduce_trees = opts.delete(:reduce_trees) { proc { |trees| trees.uniq.sort_by!(&:to_s) } }
      printable_requirement = opts.delete(:printable_requirement) { proc { |req| req.to_s } }
      additional_message_for_conflict = opts.delete(:additional_message_for_conflict) { proc { } }
      version_for_spec = opts.delete(:version_for_spec) { proc(&:to_s) }
      incompatible_version_message_for_conflict = opts.delete(:incompatible_version_message_for_conflict) do
        proc do |name, _conflict|
          %(#{solver_name} could not find compatible versions for #{possibility_type} "#{name}":)
        end
      end

      conflicts.sort.reduce("".dup) do |o, (name, conflict)|
        o << "\n" << incompatible_version_message_for_conflict.call(name, conflict) << "\n"
        if conflict.locked_requirement
          o << %(  In snapshot (#{name_for_locking_dependency_source}):\n)
          o << %(    #{printable_requirement.call(conflict.locked_requirement)}\n)
          o << %(\n)
        end
        o << %(  In #{name_for_explicit_dependency_source}:\n)
        trees = reduce_trees.call(conflict.requirement_trees)

        o << trees.join('\n') do |tree|
          t = "".dup
          depth = 2
          tree.each do |req|
            t << "  " * depth << req.to_s
            unless tree.last == req
              if spec = conflict.activated_by_name[name_for(req)]
                t << %( was resolved to #{version_for_spec.call(spec)}, which)
              end
              t << %( depends on)
            end
            t << %(\n)
            depth += 1
          end
          t
        end

        additional_message_for_conflict.call(o, name, conflict)

        o
      end.strip
    end
  end
end