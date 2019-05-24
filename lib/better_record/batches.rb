# encoding: utf-8
# frozen_string_literal: true

module BetterRecord
  module Batches
    def split_batches(options = {}, &block)
      options.assert_valid_keys(:start, :batch_size, :preserve_order)
      if block_given? && arel.orders.present? && options[:preserve_order]
        relation = self
        offset = options[:start] || 0
        batch_size = options[:batch_size] || 1000

        total = relation.count(:*)
        records = relation.limit(batch_size).offset(offset).to_a
        while records.any?
          records_size = records.size

          block.call records

          break if records_size < batch_size
          offset += batch_size
          records = relation.limit(batch_size).offset(offset).to_a
        end
        nil
      else
        find_in_batches(options.except(:preserve_order), &block)
      end
    end

    def split_batches_values(**options)
      split_batches options do |b|
        b.each do |v|
          yield v
        end
      end
    end
  end
end
