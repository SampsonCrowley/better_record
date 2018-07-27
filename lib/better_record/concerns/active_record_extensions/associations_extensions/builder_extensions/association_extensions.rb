require 'active_support/concern'
require 'active_record/associations'
require 'active_record/associations/builder/association'

module BetterRecord
  module AssociationsExtensions
    module BuilderExtensions
      module AssociationExtensions
        extend ActiveSupport::Concern

        included do |k_to_override|
          class << k_to_override
            alias_method :og_valid_options, :valid_options

            def valid_options(options)
              og_valid_options(options) + [ :primary_type, :strict_primary_type ]
            end
          end
        end
      end
    end
  end
end

ActiveRecord::Associations::Builder::Association.send(:include, BetterRecord::AssociationsExtensions::BuilderExtensions::AssociationExtensions)
