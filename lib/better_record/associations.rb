module BetterRecord
  module Associations
    class AssociationScope #:nodoc:
      def self.get_bind_values(owner, chain)
        binds = []
        last_reflection = chain.last

        binds << last_reflection.join_id_for(owner)
        if last_reflection.type
          binds << owner.class.__send__(last_reflection.options[:primary_type].presence || BetterRecord.default_polymorphic_method.presence || :polymorphic_name)
        end

        chain.each_cons(2).each do |reflection, next_reflection|
          if reflection.type
            binds << next_reflection.klass.__send__(reflection.options[:primary_type].presence || next_reflection[:primary_type].presence || BetterRecord.default_polymorphic_method.presence || :polymorphic_name)
          end
        end
        binds
      end

      private
        def last_chain_scope(scope, reflection, owner)
          join_keys = reflection.join_keys
          key = join_keys.key
          foreign_key = join_keys.foreign_key

          table = reflection.aliased_table
          value = transform_value(owner[foreign_key])
          scope = apply_scope(scope, table, key, value)

          if reflection.type
            polymorphic_type = transform_value(owner.class.__send__(reflection.options[:primary_type].presence || BetterRecord.default_polymorphic_method.presence || :polymorphic_name))
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
            value = transform_value(next_reflection.klass.__send__(reflection.options[:primary_type].presence || BetterRecord.default_polymorphic_method.presence || :polymorphic_name))
            scope = apply_scope(scope, table, reflection.type, value)
          end

          scope.joins!(join(foreign_table, constraint))
        end
    end

    module Builder
      class Association
        def self.valid_options(options)
          VALID_OPTIONS + [ :primary_type ] + Association.extensions.flat_map(&:valid_options)
        end
      end
    end

    class BelongsToAssociation
    end

    class BelongsToPolymorphicAssociation < BelongsToAssociation
      def klass
        type = owner[reflection.foreign_type]
        type.presence && type.capitalize.singularize.constantize
      end
    end
  end
end
