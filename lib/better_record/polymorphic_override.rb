module BetterRecord
  class PolymorphicOverride
    def self.polymorphic_value(klass, options = nil)
      type_val = nil
      type_method = polymorphic_method(options.presence || {})
      begin
        type_val = klass.__send__(type_method)
      rescue
        puts type_method, klass, type_val
        if type_val == :table_name_without_schema
          type_val = klass.table_name
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
      keys = [ :polymorphic_name, :table_name ]
      keys |= [BetterRecord.default_polymorphic_method] if BetterRecord.default_polymorphic_method.present?
      p keys
      values = []
      keys.each do |k|
        val = nil
        begin
          val = klass.__send__(k)
          values << val if val.present?
        rescue
        end
      end
      values
    end
  end
end
