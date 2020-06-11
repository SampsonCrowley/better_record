# frozen_string_literal: true

require 'active_support/concern'

module BetterRecord
  module ModelConcerns
    module LoggedActionBase
      extend ActiveSupport::Concern

      ACTIONS = {
        D: 'DELETE',
        I: 'INSERT',
        U: 'UPDATE',
        T: 'TRUNCATE',
        A: 'ARCHIVE',
      }.with_indifferent_access

      included do
        belongs_to :record,
          polymorphic: :true,
          primary_type: :table_name,
          foreign_key: :row_id,
          foreign_type: :table_name,
          optional: true
      end

      class_methods do
        def default_print
          [
            :event_id,
            :row_id,
            :full_name,
            :app_user_id,
            :app_user_type,
            :action_type,
            :changed_columns
          ]
        end
      end

      def changed_columns
        (self.changed_fields || {}).keys.join(', ').presence || 'N/A'
      end

      def action_type
        ACTIONS[action] || 'UNKNOWN'
      end
    end
  end
end
