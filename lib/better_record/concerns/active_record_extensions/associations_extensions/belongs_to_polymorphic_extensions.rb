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
          type.presence &&
            BetterRecord.model_index_by_table_name[type] ||= find_model_from_table_name(type)
        end

        def replace_keys record
          super
          owner[reflection.foreign_type] = record ? get_type_value(record) : nil
        end

        def get_type_value record
          BetterRecord::PolymorphicOverride.polymorphic_value(record.class, reflection.options)
        end

        def find_model_from_table_name(type)
          found_model = nil

          begin
            found_model = sub_string.classify.constantize
            return found_model
          rescue
            found_model = nil
          end

          permeate_options(type.to_s.underscore).each do |sub_string|
            begin
              found_model = sub_string.classify.constantize
            rescue
              found_model = nil
            end
            break if found_model
          end

          raise "Model Not Found: #{type}" unless found_model

          found_model
        end

        def permeate_options(type)
          str = type.dup.sub(/^_+/, '').gsub(/_+/, '_')
          Enumerator.new do |y|
            if str =~ /_/
              split_str = str.split('_')

              underscores = str.gsub(/[^_]+/, '').split('')

              [*underscores, *Array.new(underscores.size, '/')].permutation(underscores.size).each do |mutation|
                y << split_str.zip(mutation).flatten.join
              end
            else
              y << str
            end
          end
        end
      end
    end
  end
end

ActiveRecord::Associations::BelongsToPolymorphicAssociation.send(:include, BetterRecord::AssociationsExtensions::BelongsToPolymorphicAssociationExtensions)
