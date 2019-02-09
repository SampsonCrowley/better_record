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
        connection.execute(%Q(SELECT 1 FROM #{BetterRecord::LoggedAction.table_name.sub('_view', '')}_#{self.table_name} LIMIT 1))

        self.const_set(:LoggedAction, Class.new(ApplicationRecord))
        self.const_get(:LoggedAction).table_name = "#{BetterRecord::LoggedAction.table_name}_#{self.table_name}"
      rescue ActiveRecord::StatementInvalid
        self.const_set(:LoggedAction, BetterRecord::LoggedAction)
      end

      self.has_many self.audit_relation_name,
        class_name: "#{self.to_s}::LoggedAction",
        primary_type: :table_name,
        foreign_key: :row_id,
        foreign_type: :table_name,
        as: self.audit_relation_name

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
        primary_type: :table_name,
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

          base_q = lm.where(table_name: self.table_name)
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
