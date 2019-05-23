# frozen_string_literal: true

require 'active_record/reflection'

module ActiveRecord
  module Reflection
    class AbstractReflection
      def join_scope(table, foreign_table, foreign_klass = nil)
        unless foreign_klass
          foreign_klass = foreign_table
          foreign_table = nil
        end

        predicate_builder = predicate_builder(table)
        scope_chain_items = join_scopes(table, predicate_builder)
        klass_scope       = klass_join_scope(table, predicate_builder)

        key         = join_keys.key
        foreign_key = join_keys.foreign_key

        klass_scope.where!(table[key].eq(foreign_table[foreign_key])) if foreign_table

        if type
          if options[:strict_primary_type]
            klass_scope.where!(type => BetterRecord::PolymorphicOverride.polymorphic_value(foreign_klass, options))
          else
            klass_scope.where!(type => BetterRecord::PolymorphicOverride.all_types(foreign_klass))
          end
        end

        ntc =
          begin
            klass.finder_needs_type_condition?
          rescue
            false
          end

        if ntc
          klass_scope.where!(klass.send(:type_condition, table))
        end

        scope_chain_items.inject(klass_scope, &:merge!)
      end
    end

    class MacroReflection < AbstractReflection
    end

    class ThroughReflection < AbstractReflection #:nodoc:
      delegate :foreign_key, :foreign_type, :association_foreign_key, :join_id_for,
               :active_record_primary_key, :type, :get_join_keys, to: :source_reflection
    end

    class PolymorphicReflection < AbstractReflection # :nodoc:
      delegate :klass, :scope, :plural_name, :type, :get_join_keys, :scope_for, to: :@reflection
    end

    class RuntimeReflection < AbstractReflection # :nodoc:
      delegate :scope, :type, :constraints, :get_join_keys, :options, to: :@reflection
    end
  end
end
