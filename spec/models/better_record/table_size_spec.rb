require 'rails_helper'

module BetterRecord
  RSpec.describe TableSize, type: :model do
    #           oid: :integer, required
    #        schema: :string
    #          name: :string
    # apx_row_count: :float
    #   total_bytes: :integer
    #     idx_bytes: :integer
    #   toast_bytes: :integer
    #     tbl_bytes: :integer
    #         total: :text
    #           idx: :text
    #         toast: :text
    #           tbl: :text
    describe 'Class Methods' do
      self.use_transactional_tests = false

      describe 'reload_data' do
        it "sends UPDATE_TABLE_SIZES_SQL to connection.execute" do
          expect(described_class.connection).to receive(:execute).with described_class::UPDATE_TABLE_SIZES_SQL
          described_class.reload_data
        end

        it "updates last updated time", testing_transactions: true do
          last_update = described_class.last_updated || Time.now
          next_update = described_class.reload_data
          expect(next_update).to eq described_class.last_updated
          expect(described_class.last_updated).to be > last_update
        end
      end

      describe 'all' do
        it 'reloads stale data' do
          described_class.last_updated = 2.hours.ago
          expect(described_class).to receive(:reload_data)
          described_class.all
        end

        it 'is scoped to public tables by default' do
          expect(described_class.all.size).to eq ApplicationRecord.connection.execute(
            <<-SQL
              SELECT COUNT(c.oid) count
              FROM pg_class c
              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
              WHERE relkind = 'r'
              AND (nspname = 'public')
            SQL
          ).first['count']
        end

        it 'returns table size data for all tables' do
          expect(described_class.all.unscoped.size).to eq ApplicationRecord.connection.execute(
            <<-SQL
              SELECT COUNT(pg_class.oid) count
              FROM pg_class
              WHERE relkind = 'r'
            SQL
          ).first['count']
        end
      end
    end
  end
end
