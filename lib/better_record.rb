# frozen_string_literal: true

require 'active_support'
require 'active_record'
require 'active_record/type'
require 'csv'

Dir.glob("#{File.expand_path(__dir__)}/core_ext/*.rb").each do |d|
  require d
end

module BetterRecord
  ATTRIBUTE_METHODS = [
    :strict_booleans,
    :default_polymorphic_method,
    :db_audit_schema,
    :has_auditing_relation_by_default,
    :audit_relation_name,
    :layout_template,
    :app_domain_name,
    :after_login_path,
    :use_bearer_token,
    :session_class,
    :session_column,
    :session_data,
    :session_authenticate_method,
    :disallow_sessions,
    :certificate_session_class,
    :certificate_session_column,
    :certificate_session_user_method,
    :certificate_header,
    :certificate_is_hashed,
    :certificate_cleaning_method,
    :certificate_cleaning_send_as_arg,
    :token_encryption_method,
    :token_decryption_method,
    :token_send_as_arg,
  ].freeze

  class << self
    def attributes
      attrs_hash.dup
    end

    def model_index_by_table_name(reset = false)
      @index_by_table_name = nil if reset
      
      @index_by_table_name ||= ActiveRecord::Base.descendants.reject(&:abstract_class).index_by(&:table_name)
    end

    attr_accessor *ATTRIBUTE_METHODS

    # ATTRIBUTE_METHODS.each do |method|
    #   if method.to_s =~ /_class/
    #     define_method method do
    #       val = instance_variable_get(:"@#{method}")
    #       val.is_a?(String) ? __send__(:"#{method}=", val.constantize) : val
    #     end
    #
    #     define_method :"#{method}=" do |val|
    #       instance_variable_set(:"@#{method}", val)
    #     end
    #   end
    # end

    private
      def attrs_hash
        @attrs ||= ATTRIBUTE_METHODS.map {|k| [k, true]}.to_h.with_indifferent_access.freeze
      end
  end

  self.strict_booleans = Boolean.strict_parse((ENV.fetch('BR_STRICT_BOOLEANS') { false }))
  self.default_polymorphic_method = (ENV.fetch('BR_DEFAULT_POLYMORPHIC_METHOD') { :polymorphic_name }).to_sym
  self.db_audit_schema = ENV.fetch('BR_DB_AUDIT_SCHEMA') { 'auditing' }
  self.has_auditing_relation_by_default = Boolean.strict_parse(ENV.fetch('BR_ADD_HAS_MANY') { true })
  self.audit_relation_name = (ENV.fetch('BR_AUDIT_RELATION_NAME') { 'logged_actions' }).to_sym
  self.layout_template = (ENV.fetch('BR_LAYOUT_TEMPLATE') { 'better_record/application' }).to_s
  self.app_domain_name = (ENV.fetch('APP_DOMAIN_NAME') { 'non_existant_domain.com' }).to_s
  self.after_login_path = (ENV.fetch('BR_AFTER_LOGIN_PATH') { nil })
  self.use_bearer_token = Boolean.strict_parse(ENV.fetch('BR_USE_BEARER_TOKEN') { false })
  self.session_column = (ENV.fetch('BR_SESSION_COLUMN') { :id }).to_sym
  self.session_authenticate_method = (ENV.fetch('BR_SESSION_AUTHENTICATE_METHOD') { :authenticate }).to_sym
  self.certificate_session_column = (ENV.fetch('BR_CERTIFICATE_SESSION_COLUMN') { :certificate }).to_sym
  self.certificate_session_user_method = (ENV.fetch('BR_CERTIFICATE_SESSION_USER_METHOD') { :user }).to_sym
  self.certificate_header = (ENV.fetch('BR_CERTIFICATE_HEADER') { :HTTP_X_SSL_CERT }).to_sym
  self.certificate_is_hashed = Boolean.strict_parse(ENV.fetch('BR_CERTIFICATE_IS_HASHED') { false })
  self.certificate_cleaning_method = (ENV.fetch('BR_CERTIFICATE_CLEANING_METHOD') { :clean_certificate })&.to_sym
  self.certificate_cleaning_send_as_arg = Boolean.strict_parse(ENV.fetch('BR_CERTIFICATE_CLEANING_AS_ARG') { false })
  self.disallow_sessions = Boolean.strict_parse(ENV.fetch('BR_DISALLOW_SESSIONS') { false })
  self.token_decryption_method = (ENV.fetch('BR_TOKEN_DECRYPTION_METHOD') { '' }).presence&.to_sym
  self.token_encryption_method = (ENV.fetch('BR_TOKEN_ENCRYPTION_METHOD') { '' }).presence&.to_sym
  self.token_send_as_arg = Boolean.strict_parse(ENV.fetch('BR_TOKEN_AS_ARG') { false })
end

require "#{File.expand_path(__dir__)}/better_record/custom_type.rb"

Dir.glob("#{File.expand_path(__dir__)}/better_record/*.rb").each do |d|
  require d unless (d =~ /fake|custom_type/)
end

ActiveSupport.on_load(:active_record) do
  module ActiveRecord
    module Batches
      include BetterRecord::Batches
    end
    class Migration
      include BetterRecord::Migration
    end
    module ConnectionAdapters
      class TableDefinition
        include BetterRecord::ExchangeRateInteger::TableDefinition
        include BetterRecord::Gender::TableDefinition
        include BetterRecord::MoneyInteger::TableDefinition
        include BetterRecord::ThreeState::TableDefinition
      end
    end
  end
end
