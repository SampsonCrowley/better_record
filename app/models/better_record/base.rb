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
    if (ha = BetterRecord.has_auditing_relation_by_default)
      class << self
        define_method BetterRecord.audit_relation_name do |*args, &block|
          @logger_model ||=
            begin
              connection.execute(%Q(SELECT 1 FROM #{BetterRecord::LoggedAction.table_name}_#{self.table_name} LIMIT 1))

              class self.to_s.constantize::LoggedAction < BetterRecord::LoggedAction
                self.table_name = "#{BetterRecord::LoggedAction.table_name}_#{self.to_s.deconstantize.constantize.table_name}"
                self
              end
            rescue ActiveRecord::StatementInvalid
              class self.to_s.constantize::LoggedAction < BetterRecord::LoggedAction
                self
              end
            end

          return @logger_model if args.present? && args.first == 'SETTING_INHERITANCE'

          base_q = @logger_model.where(table_name: self.table_name)
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

      def self.inherited(child)
        super
        TracePoint.trace(:end) do |t|
          if child == t.self
            child.set_audits_methods!
            t.disable
          end
        end
      end
    end
    # == Validations ==========================================================

    # == Scopes ===============================================================

    # == Callbacks ============================================================

    # == Boolean Class Methods ================================================

    # == Class Methods ========================================================
    def self.set_audits_methods!
      m = __send__ BetterRecord.audit_relation_name, 'SETTING_INHERITANCE'
      self.has_many self.audit_relation_name,
        class_name: m.to_s,
        primary_type: :table_name,
        foreign_key: :row_id,
        foreign_type: :table_name,
        as: self.audit_relation_name
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


  end
end
