require "active_support"

class Boolean
  def self.parse(value)
    ActiveRecord::Type::Boolean.new.cast(value)
  end
end

class Object
  def yes_no_to_s
    !!self == self ? (self ? 'yes' : 'no') : to_s
  end
end

module BetterRecord
  class << self
    attr_accessor :default_polymorphic_method, :db_audit_schema, :has_audits_by_default
  end
  self.default_polymorphic_method = :polymorphic_name
  self.db_audit_schema = ENV.fetch('DB_AUDIT_SCHEMA') { 'auditing' }
  self.has_audits_by_default = Boolean.parse(ENV.fetch('BR_ADD_HAS_MANY') { false })
end

Dir.glob("#{File.expand_path(__dir__)}/better_record/*").each do |d|
  require d
end

ActiveSupport.on_load(:active_record) do
  module ActiveRecord
    include BetterRecord::Associations
    include BetterRecord::Batches
    include BetterRecord::Migration
    include BetterRecord::Reflection
    include BetterRecord::Relation
  end
  include BetterRecord::NullifyBlankAttributes
end
