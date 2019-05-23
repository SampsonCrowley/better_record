# frozen_string_literal: true

require 'active_support/concern'
require 'active_record/associations'
require 'active_record/associations/association'

module BetterRecord
  module AssociationsExtensions
    module AssociationExtensions
      extend ActiveSupport::Concern

      included do
        def creation_attributes
          attributes = {}

          if (reflection.has_one? || reflection.collection?) && !options[:through]
            attributes[reflection.foreign_key] = owner[reflection.active_record_primary_key]

            if reflection.type
              attributes[reflection.type] = get_type_value
            end
          end

          attributes
        end

        def get_type_value
          BetterRecord::PolymorphicOverride.polymorphic_value(owner.class, reflection.options)
        end
      end
    end
  end
end

ActiveRecord::Associations::Association.send(:include, BetterRecord::AssociationsExtensions::AssociationExtensions)
