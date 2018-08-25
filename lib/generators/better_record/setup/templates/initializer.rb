# frozen_string_literal: true

module BetterRecord
  ##########################################################################
  #   THE FOLLOWING SETTINGS CAN ALSO BE SET THROUGH ENVIRONMENT VARIABLES #
  #                                                                        #
  #                  strict_booleans: BR_STRICT_BOOLEANS                   #
  #       default_polymorphic_method: BR_DEFAULT_POLYMORPHIC_METHOD        #
  #                  db_audit_schema: BR_DB_AUDIT_SCHEMA                   #
  # has_auditing_relation_by_default: BR_ADD_HAS_MANY                      #
  #              audit_relation_name: BR_AUDIT_RELATION_NAME               #
  #                  layout_template: BR_LAYOUT_TEMPLATE                   #
  #                  app_domain_name: APP_DOMAIN_NAME                      #
  #                 after_login_path: BR_AFTER_LOGIN_PATH                  #
  #                 use_bearer_token: BR_USE_BEARER_TOKEN                  #
  #                   session_column: BR_SESSION_COLUMN                    #
  #      session_authenticate_method: BR_SESSION_AUTHENTICATE_METHOD       #
  #       certificate_session_column: BR_CERTIFICATE_SESSION_COLUMN        #
  #  certificate_session_user_method: BR_CERTIFICATE_SESSION_USER_METHOD   #
  ##########################################################################

  # uncomment the following line to disable three-state booleans in models

  # self.strict_booleans = true

  # uncomment the following line to use table_names instead of model names
  # as the 'type' value in polymorphic relationships

  # self.default_polymorphic_method = :table_name

  # uncomment the following line to use change the database schema
  # for auditing functions and logged_actions. DEFAULT - 'auditing'

  # self.db_audit_schema = 'audit'

  # uncomment the following line to add an association for table audits
  # directly to ActiveRecord::Base. DEFAULT - false

  # self.has_auditing_relation_by_default = true

  # uncomment the following line to change the association name for
  # auditing lookups. DEFAULT - :audits

  # self.audit_relation_name = :logged_actions

  # uncomment the following line to change the layout template used by
  # BetterRecord::ActionController. DEFAULT - 'better_record/layout'

  # self.layout_template = 'layout'

  # uncomment the following line to set the domain your application
  # runs under. Used in setting DKIM params. DEFAULT - 'non_existant_domain.com'

  # self.app_domain_name = 'default_app_name.com'

  # uncomment and set the session_class to enable gem handled session management
  # all other settings are optional

  # self.session_class = User

  # OPTIONAL #

  # set to true to use Auth headers instead of session cookies
  # self.use_bearer_token = true

  # self.after_login_path = Rails.application.routes.url_helpers.root_path

  # self.session_column = :uuid

  # self.session_data = ->(user) do
  #   {
  #     user_id: user.uuid,
  #     first_access: user.first_login_time,
  #     created_at: Time.now
  #   }
  # end

  # self.session_authenticate_method = :check_login

  # self.certificate_session_class = Staff.includes(:user)

  # self.certificate_session_column = :cert_str

  # self.certificate_session_user_method = :user
end

# uncomment the following lines to set the keys needed for JWT token auth

# BetterRecord::JWT.signing_key = ENV.fetch('JWT_SIGNING_KEY') { nil }
# BetterRecord::JWT.encryption_key = ENV.fetch('JWT_ENCRYPTION_KEY') { nil }
