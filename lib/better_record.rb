require 'active_support'
require 'active_record'
require 'csv'

Dir.glob("#{File.expand_path(__dir__)}/core_ext/*.rb").each do |d|
  require d
end

module BetterRecord
  ATTRIBUTE_METHODS = [
    :default_polymorphic_method,
    :db_audit_schema,
    :has_auditing_relation_by_default,
    :audit_relation_name,
    :layout_template,
    :app_domain_name,
    :after_login_path,
    :session_class,
    :session_column,
    :session_data,
    :session_authenticate_method,
    :certificate_session_class,
    :certificate_session_column,
    :certificate_session_user_method,
  ].freeze

  class << self
    def attributes
      attrs_hash.dup
    end

    attr_accessor *ATTRIBUTE_METHODS

    private
      def attrs_hash
        @attrs ||= ATTRIBUTE_METHODS.map {|k| [k, true]}.to_h.with_indifferent_access.freeze
      end
  end

  self.default_polymorphic_method = (ENV.fetch('BR_DEFAULT_POLYMORPHIC_METHOD') { :polymorphic_name }).to_sym
  self.db_audit_schema = ENV.fetch('BR_DB_AUDIT_SCHEMA') { 'auditing' }
  self.has_auditing_relation_by_default = ActiveRecord::Type::Boolean.new.cast(ENV.fetch('BR_ADD_HAS_MANY') { true })
  self.audit_relation_name = (ENV.fetch('BR_AUDIT_RELATION_NAME') { 'logged_actions' }).to_sym
  self.layout_template = (ENV.fetch('BR_LAYOUT_TEMPLATE') { 'better_record/layout' }).to_s
  self.app_domain_name = (ENV.fetch('APP_DOMAIN_NAME') { 'non_existant_domain.com' }).to_s
  self.after_login_path = (ENV.fetch('BR_AFTER_LOGIN_PATH') { nil })
  self.session_column = (ENV.fetch('BR_SESSION_COLUMN') { :id }).to_sym
  self.session_authenticate_method = (ENV.fetch('BR_SESSION_AUTHENTICATE_METHOD') { :authenticate }).to_sym
  self.certificate_session_column = (ENV.fetch('BR_CERTIFICATE_SESSION_COLUMN') { :certificate }).to_sym
  self.certificate_session_user_method = (ENV.fetch('BR_CERTIFICATE_SESSION_USER_METHOD') { :user }).to_sym
end

Dir.glob("#{File.expand_path(__dir__)}/better_record/*.rb").each do |d|
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
end
# !centered[## [Men's Results](/assets/pdfs/2018-golf-international-results-male.pdf)--br--[![Mens Results](/assets/images/2018-golf-international-results-male.jpg)](/assets/pdfs/2018-golf-international-results-male.pdf)]
# !centered[## [Women's Results](/assets/pdfs/2018-golf-international-results-female.pdf)--br--[![Womens Results](/assets/images/2018-golf-international-results-female.jpg)](/assets/pdfs/2018-golf-international-results-female.pdf)]
# !centered[## [Team Results](/assets/pdfs/2018-golf-international-results-team.pdf)--br--[![Team Results](/assets/images/2018-golf-international-results-team)](/assets/pdfs/2018-golf-international-results-team.pdf)]
#
# !centered[## [Team Results](/assets/pdfs/2018-golf-international-results-summary.pdf)--br--[![Team Results](/assets/images/2018-golf-international-results-summary.jpg)](/assets/pdfs/2018-golf-international-results-summary.pdf)]
# !centered[## [Individual Results](/assets/pdfs/2018-golf-international-results.pdf)--br--[![Team Results](/assets/images/2018-golf-international-results.jpg)](/assets/pdfs/2018-golf-international-results.pdf)]
