# frozen_string_literal: true

require 'active_support/concern'
require 'active_record/associations'
require 'active_record/associations/association_scope'

module BetterRecord
  module AssociationsExtensions
    module AssociationScopeExtensions
      extend ActiveSupport::Concern

      included do
        def self.get_bind_values(owner, chain)
          binds = []
          last_reflection = chain.last

          binds << last_reflection.join_id_for(owner)
          if last_reflection.type
            binds << BetterRecord::PolymorphicOverride.polymorphic_value(owner.class, last_reflection.options.presence)
          end

          chain.each_cons(2).each do |reflection, next_reflection|
            if reflection.type
              binds << BetterRecord::PolymorphicOverride.polymorphic_value(next_reflection.klass, (reflection.options[:primary_type].present? ? reflection.options : next_reflection.options))
            end
          end
          binds
        end

        def last_chain_scope(scope, reflection, owner)
          join_keys = reflection.join_keys
          key = join_keys.key
          foreign_key = join_keys.foreign_key

          table = reflection.aliased_table
          value = transform_value(owner[foreign_key])
          scope = apply_scope(scope, table, key, value)

          if reflection.type
            polymorphic_type = transform_value(BetterRecord::PolymorphicOverride.polymorphic_value(owner.class, reflection.options))
            scope = apply_scope(scope, table, reflection.type, polymorphic_type)
          end

          scope
        end


        def next_chain_scope(scope, reflection, next_reflection)
          join_keys = reflection.join_keys
          key = join_keys.key
          foreign_key = join_keys.foreign_key

          table = reflection.aliased_table
          foreign_table = next_reflection.aliased_table
          constraint = table[key].eq(foreign_table[foreign_key])

          if reflection.type
            value = transform_value(BetterRecord::PolymorphicOverride.polymorphic_value(next_reflection.klass, reflection.options))
            scope = apply_scope(scope, table, reflection.type, value)
          end

          scope.joins!(join(foreign_table, constraint))
        end
      end
    end
  end
end

ActiveRecord::Associations::AssociationScope.send(:include, BetterRecord::AssociationsExtensions::AssociationScopeExtensions)
