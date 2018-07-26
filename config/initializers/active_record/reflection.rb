module ActiveRecord
  module Reflection
    class AbstractReflection
      def join_scope(table, foreign_klass)
        predicate_builder = predicate_builder(table)
        scope_chain_items = join_scopes(table, predicate_builder)
        klass_scope       = klass_join_scope(table, predicate_builder)

        if type
          klass_scope.where!(type => foreign_klass.__send__(options[:primary_type] || :table_name))
        end

        scope_chain_items.inject(klass_scope, &:merge!)
      end
    end

    class RuntimeReflection < AbstractReflection # :nodoc:
      delegate :scope, :type, :constraints, :get_join_keys, :options, to: :@reflection
    end
  end
end
