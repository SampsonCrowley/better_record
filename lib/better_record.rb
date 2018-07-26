require "active_support"

module BetterRecord
  class << self
    attr_accessor :default_polymorphic_method,
                  :db_audit_schema,
                  :has_audits_by_default,
                  :audit_relation_name,
                  :layout_template,
                  :app_domain_name
  end
  self.default_polymorphic_method = (ENV.fetch('BR_DEFAULT_POLYMORPHIC_METHOD') { :polymorphic_name }).to_sym
  self.db_audit_schema = ENV.fetch('BR_DB_AUDIT_SCHEMA') { 'auditing' }
  self.has_audits_by_default = ActiveRecord::Type::Boolean.new.cast(ENV.fetch('BR_ADD_HAS_MANY') { false })
  self.audit_relation_name = (ENV.fetch('BR_AUDIT_RELATION_NAME') { 'audits' }).to_sym
  self.layout_template = (ENV.fetch('BR_LAYOUT_TEMPLATE') { 'better_record/layout' }).to_s
  self.app_domain_name = (ENV.fetch('APP_DOMAIN_NAME') { 'non_existant_domain.com' }).to_s
end

Dir.glob("#{File.expand_path(__dir__)}/better_record/*").each do |d|
  require d unless (d =~ /fake/)
end

ActiveSupport.on_load(:active_record) do
  module ActiveRecord
    module Batches
      include BetterRecord::Batches
    end
    class Migration
      include BetterRecord::Migration
    end
  end
  include BetterRecord::NullifyBlankAttributes
end
