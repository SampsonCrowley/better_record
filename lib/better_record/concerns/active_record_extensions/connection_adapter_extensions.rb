module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module OID # :nodoc:
        class Enum < Type::Value
          attr_accessor :value_array, :type_override

          def cast(value)
            value_array ? value_array.find {|v| /^#{v}/i =~ value.to_s } : value.to_s
          end

          def type
            type_override || :enum
          end

          private

            def cast_value(value)
              value_array ? value_array.find {|v| /^#{v}/i =~ value.to_s } : value.to_s
            end
        end
        # This class uses the data from PostgreSQL pg_type table to build
        # the OID -> Type mapping.
        #   - OID is an integer representing the type.
        #   - Type is an OID::Type object.
        # This class has side effects on the +store+ passed during initialization.

        class TypeMapInitializer # :nodoc:
          private
            def register_domain_type(row)
              if (in_reg = check_registry(row['typname']))
                register row['oid'], ActiveRecord::Type.registry.lookup(in_reg.send :name)
              elsif base_type = @store.lookup(row["typbasetype"].to_i)
                register row["oid"], base_type
              else
                warn "unknown base type (OID: #{row["typbasetype"]}) for domain #{row["typname"]}."
              end
            end

            def register_enum_type(row)
              enum_val = OID::Enum.new
              enum_val.value_array = row['enumlabel'][1..-2].split(',').presence
              enum_val.value_array.map!(&:to_i) if enum_val.value_array.all? {|v| v =~ /^[0-9]+$/}

              enum_val.type_override = (val = check_registry(row['typname'])) && val.__send__(:name)

              register row["oid"], enum_val
            end

            def check_registry(name)
              ActiveRecord::Type.registry.__send__(:registrations).find do |type|
                if type.matches?(name.to_sym)
                  true
                elsif type.matches?(name)
                  true
                end
              end
            end

        end
      end
    end

    class PostgreSQLAdapter
      private
        def load_additional_types(oids = nil)
          initializer = OID::TypeMapInitializer.new(type_map)

          if supports_ranges?
            query = <<-SQL
              SELECT t.oid, t.typname, t.typelem, t.typdelim, t.typinput, r.rngsubtype, t.typtype, t.typbasetype,
                     array_agg(e.enumlabel) as enumlabel
              FROM pg_type as t
              LEFT JOIN pg_range as r ON t.oid = r.rngtypid
              LEFT JOIN pg_catalog.pg_enum as e ON t.oid = e.enumtypid
            SQL
          else
            query = <<-SQL
              SELECT t.oid, t.typname, t.typelem, t.typdelim, t.typinput, t.typtype, t.typbasetype
              FROM pg_type as t
            SQL
          end

          if oids
            query += "WHERE t.oid::integer IN (%s)" % oids.join(", ")
          else
            query += initializer.query_conditions_for_initial_load
          end

          if supports_ranges?
            query += " GROUP BY 1,2,3,4,5,6,7,8"
          end

          execute_and_clear(query, "SCHEMA", []) do |records|
            initializer.run(records)
          end
        end
    end
  end
end
