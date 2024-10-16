module Molinillo
  module Delegates
    # Delegates all {Molinillo::SpecificationProvider} methods to a
    # `#specification_provider` property.
    module SpecificationProvider
      # (see Molinillo::SpecificationProvider#search_for)
      def search_for(dependency)
        with_no_such_dependency_error_handling do
          specification_provider.search_for(dependency)
        end
      end

      # (see Molinillo::SpecificationProvider#dependencies_for)
      def dependencies_for(specification)
        with_no_such_dependency_error_handling do
          specification_provider.dependencies_for(specification)
        end
      end

      # (see Molinillo::SpecificationProvider#requirement_satisfied_by?)
      def requirement_satisfied_by?(requirement, activated, spec)
        with_no_such_dependency_error_handling do
          specification_provider.requirement_satisfied_by?(requirement, activated, spec)
        end
      end

      # (see Molinillo::SpecificationProvider#name_for)
      def name_for(dependency)
        with_no_such_dependency_error_handling do
          specification_provider.name_for(dependency)
        end
      end

      # (see Molinillo::SpecificationProvider#name_for_explicit_dependency_source)
      def name_for_explicit_dependency_source
        with_no_such_dependency_error_handling do
          specification_provider.name_for_explicit_dependency_source
        end
      end

      # (see Molinillo::SpecificationProvider#name_for_locking_dependency_source)
      def name_for_locking_dependency_source
        with_no_such_dependency_error_handling do
          specification_provider.name_for_locking_dependency_source
        end
      end

      # (see Molinillo::SpecificationProvider#sort_dependencies)
      def sort_dependencies(dependencies, activated, conflicts)
        with_no_such_dependency_error_handling do
          specification_provider.sort_dependencies(dependencies, activated, conflicts)
        end
      end

      # (see Molinillo::SpecificationProvider#allow_missing?)
      def allow_missing?(dependency)
        with_no_such_dependency_error_handling do
          specification_provider.allow_missing?(dependency)
        end
      end

      # Ensures any raised {NoSuchDependencyError} has its
      # {NoSuchDependencyError#required_by} set.
      # @yield
      private def with_no_such_dependency_error_handling(&)
        yield
      rescue error : NoSuchDependencyError
        if state
          # TODO
          # vertex = activated.vertex_named(name_for(error.dependency))
          # error.required_by += vertex.incoming_edges.map { |e| e.origin.name }
          # error.required_by << name_for_explicit_dependency_source unless vertex.explicit_requirements.empty?
        end
        raise error
      end
    end
  end
end
