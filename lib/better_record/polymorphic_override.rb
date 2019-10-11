# frozen_string_literal: true

module BetterRecord
  class PolymorphicOverride
    @@debugging_override = nil

    def self.debug=(val)
      @@debugging_override = !!val
    end

    def self.debug
      !!@@debugging_override
    end

    def self.polymorphic_value(klass, options = nil)
      type_val = nil
      type_method = polymorphic_method(options.presence || {})
      begin
        type_val = klass.__send__(type_method)
      rescue
        puts "Error in Polymorphic Value:",
          type_method, klass, type_val,
          $!.message, $!.backtrace if debug

        if type_val == :table_name_without_schema
          type_val = klass.table_name.to_s.split('.').first
        else
          type_val = klass.polymorphic_name
        end
      end
      type_val
    end

    def self.polymorphic_method(options = {})
      (options[:primary_type].presence) || BetterRecord.default_polymorphic_method.presence || :polymorphic_name
    end

    def self.all_types(klass)
      keys = [ :polymorphic_name, :full_table_name, :table_name_only, :table_name ]
      keys |= [BetterRecord.default_polymorphic_method] if BetterRecord.default_polymorphic_method.present?
      p "Polymorphic methods:", keys if debug
      values = []
      keys.each do |k|
        val = nil
        begin
          val = klass.__send__(k)
          values << val if val.present?
        rescue
          p "Error in Polymorphic Method, #{k}:", $!.message, $!.backtrace if debug
        end
      end
      p "Present Polymorphic Values:", values if debug
      values.uniq
    end
  end
end
