# frozen_string_literal: true

require 'active_support/concern'
require 'active_record/associations'
require 'active_record/associations/belongs_to_polymorphic_association'

module BetterRecord
  module AssociationsExtensions
    module BelongsToPolymorphicAssociationExtensions
      extend ActiveSupport::Concern

      included do
        def klass
          type = owner[reflection.foreign_type]
          type.presence && type.capitalize.singularize.constantize
        end

        def replace_keys record
          super
          owner[reflection.foreign_type] = record ? get_type_value(record) : nil
        end

        def get_type_value record
          BetterRecord::PolymorphicOverride.polymorphic_value(record.class, reflection.options)
        end
      end
    end
  end
end

ActiveRecord::Associations::BelongsToPolymorphicAssociation.send(:include, BetterRecord::AssociationsExtensions::BelongsToPolymorphicAssociationExtensions)
