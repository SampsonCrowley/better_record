require 'rails_helper'

module BetterRecord
  RSpec.describe LoggedAction, type: :model do
    describe 'Attributes' do
      #          event_id: :integer, required
      #       schema_name: :text, required
      #        table_name: :text, required
      #             relid: :oid, required
      # session_user_name: :text
      #       app_user_id: :integer
      #     app_user_type: :text
      #    app_ip_address: :inet
      #  action_tstamp_tx: :datetime, required
      # action_tstamp_stm: :datetime, required
      # action_tstamp_clk: :datetime, required
      #    transaction_id: :integer
      #  application_name: :text
      #       client_addr: :inet
      #       client_port: :integer
      #      client_query: :text
      #            action: :text, required
      #            row_id: :integer
      #          row_data: :hstore
      #    changed_fields: :hstore
      #    statement_only: :boolean, required

      pending "add some examples to (or delete) #{__FILE__} Attributes"
    end

    describe 'Associations' do
      pending "add some examples to (or delete) #{__FILE__} Attributes"
    end
  end
end
