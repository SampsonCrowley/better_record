# frozen_string_literal: true

module BetterRecord
  class Base < ActiveRecord::Base
    self.abstract_class = true
    include ModelConcerns::HasValidatedAvatar
    include ModelConcerns::HasProtectedPassword

    # == Constants ============================================================

    # == Attributes ===========================================================

    # == Extensions ===========================================================

    # == Relationships ========================================================

    # == Validations ==========================================================

    # == Scopes ===============================================================

    # == Callbacks ============================================================

    # == Boolean Class Methods ================================================

    # == Class Methods ========================================================
    def self.set_audit_methods!
      begin
        t_name = BetterRecord::LoggedAction.table_name.sub('_view', '')
        connection.execute(%Q(SELECT 1 FROM #{t_name}_#{self.table_name_only} LIMIT 1))

        self.const_set(:LoggedAction, Class.new(ApplicationRecord))
        self.const_get(:LoggedAction).table_name = "#{t_name}_#{self.table_name_only}"
        self.const_get(:LoggedAction).primary_key = :event_id
      rescue ActiveRecord::StatementInvalid
        self.const_set(:LoggedAction, BetterRecord::LoggedAction)
      end

      self.has_many self.audit_relation_name,
        class_name: "#{self.to_s}::LoggedAction",
        primary_type: :full_table_name,
        foreign_key: :row_id,
        foreign_type: :full_name,
        as: self.audit_relation_name

      self.has_many :"#{self.audit_relation_name}_full_table",
        class_name: "#{self.to_s}::LoggedAction",
        primary_type: :table_name_only,
        foreign_key: :row_id,
        foreign_type: :table_name,
        as: self.audit_relation_name

      self
    rescue ActiveRecord::NoDatabaseError
      self
    end

    def self.gender_enum(col)
      enum col, BetterRecord::Gender::ENUM
    end

    def self.get_hashed_string(str)
      ct = Time.now.to_i
      cq = ActiveRecord::Base.sanitize_sql_array(["hash_password(?) as hashed_cert_#{t}", str])
      select(cq).limit(1).first[:"hashed_cert_#{t}"]
    end

    def self.schema_qualified
      return @schema_qualified if @schema_qualified.present?
      if table_name =~ /.+\..+/
        tmp_name = table_name.split('.')
        @schema_qualified = {
          schema_name: tmp_name[0],
          table_name: tmp_name[1]
        }
      else
        paths = (connection.execute("show search_path").first || {})['search_path']
        paths = (paths.presence || "public").to_s.split(",")
        paths.each do |schema_path|
          row = (
            connection.execute <<-SQL.cleanup_production
              SELECT c.oid,
                n.nspname,
                c.relname
              FROM pg_catalog.pg_class c
                LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
              WHERE c.relname = '#{table_name}'
                AND n.nspname = '#{schema_path.strip}'
              ORDER BY 2, 3;
            SQL
          ).first

          if row.present?
            @schema_name = {
              schema_name: row['nspname'],
              table_name: row['relname']
            }
            break
          end
        end
        return @schema_name || {
          schema_name: "public",
          table_name: table_name
        }
      end
    end

    def self.full_table_name
      "#{schema_qualified[:schema_name]}.#{schema_qualified[:table_name]}"
    end

    def self.table_name_only
      schema_qualified[:table_name]
    end

    # == Boolean Methods ======================================================

    # == Instance Methods =====================================================
    def get_hashed_string(str)
      self.class.get_hashed_string(str)
    end

    def indifferent_attributes
      attributes.with_indifferent_access
    end

    def dup(allow_full_dup = false)
      if !allow_full_dup && self.class.const_defined?(:NON_DUPABLE_KEYS)
        super().tap do |r|
          r.class::NON_DUPABLE_KEYS.each {|k| r[k] = nil }
        end
      else
        super()
      end
    end


    if (ha = BetterRecord.has_auditing_relation_by_default)
      has_many self.audit_relation_name,
        class_name: 'BetterRecord::LoggedAction',
        primary_type: :full_table_name,
        foreign_key: :row_id,
        foreign_type: :full_name,
        as: self.audit_relation_name

      has_many :"#{self.audit_relation_name}_full_table",
        class_name: 'BetterRecord::LoggedAction',
        primary_type: :table_name_only,
        foreign_key: :row_id,
        foreign_type: :table_name,
        as: self.audit_relation_name

      class << self
        define_method BetterRecord.audit_relation_name do |*args, &block|
          lm =
            begin
              self.const_get(:LoggedAction)
            rescue NameError
              BetterRecord::LoggedAction
            end

          base_q = lm.where(full_name: self.full_table_name)
          base_q = base_q.where(*args) if args.present?

          if block
            base_q.split_batches do |b|
              b.each do |r|
                block.call(r)
              end
            end
          else
            base_q
          end
        end

        define_method :"#{BetterRecord.audit_relation_name}_full_table" do |*args, &block|
          lm =
            begin
              self.const_get(:LoggedAction)
            rescue NameError
              BetterRecord::LoggedAction
            end

          base_q = lm.where(table_name: self.table_name_only)
          base_q = base_q.where(*args) if args.present?

          if block
            base_q.split_batches do |b|
              b.each do |r|
                block.call(r)
              end
            end
          else
            base_q
          end
        end
      end
    end

  end
end
