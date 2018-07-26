module BetterRecord
  ##################################################################
  #   ALL SETTINGS HERE CAN BE SET THROUGH ENVIRONMENT VARIABLES   #
  #                                                                #
  #   default_polymorphic_method: BR_DEFAULT_POLYMORPHIC_METHOD    #
  #              db_audit_schema: BR_DB_AUDIT_SCHEMA               #
  #        has_audits_by_default: BR_ADD_HAS_MANY                  #
  #          audit_relation_name: BR_AUDIT_RELATION_NAME           #
  #              layout_template: BR_LAYOUT_TEMPLATE               #
  #              app_domain_name: APP_DOMAIN_NAME                  #
  ##################################################################

  # uncomment the following line to use table_names instead of model names
  # as the 'type' value in polymorphic relationships

  # self.default_polymorphic_method = :table_name

  # uncomment the following line to use change the database schema
  # for auditing functions and logged_actions. DEFAULT - 'auditing'

  # self.db_audit_schema = 'audit'

  # uncomment the following line to add an association for table audits
  # directly to ActiveRecord::Base. DEFAULT - false

  # self.has_audits_by_default = true

  # uncomment the following line to change the association name for
  # auditing lookups. DEFAULT - :audits

  # self.audit_relation_name = :logged_actions

  # uncomment the following line to change the layout template used by
  # BetterRecord::ActionController. DEFAULT - 'better_record/layout'

  # self.layout_template = 'layout'

  # uncomment the following line to set the domain your application
  # runs under. Used in setting DKIM params. DEFAULT - 'non_existant_domain.com'

  # self.app_domain_name = 'default_app_name.com'
end
