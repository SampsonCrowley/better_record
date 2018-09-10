# frozen_string_literal: true

require 'active_support/concern'
require 'active_record/base'
require_relative './base_extensions/attribute_methods'

module BetterRecord
  module BaseExtensions
    extend ActiveSupport::Concern

    included do
      include AttributeMethods::Write
      before_validation :set_booleans
    end

    class_methods do
      def audit_relation_name
        @@audit_relation_name ||= (BetterRecord.audit_relation_name.presence || :audits).to_sym
      end

      def boolean_columns
        []
      end

      def column_comments(prefix = '')
        longest_name = 0
        column_names.each {|nm| longest_name = nm.length if nm.length > longest_name}
        longest_name += 1
        str = ''.dup
        columns.each do |col|
          unless col.name == 'id'
            spaces = "#{' ' * (longest_name - col.name.length)}"
            is_required = "#{col.null == false ? ', required' : ''}"
            is_default = "#{col.default ? ", default: #{col.default}" : ''}"
            str << "#{prefix}##{spaces}#{col.name}: :#{col.type}#{is_required}\n"
          end
        end
        str
      end

      def current_user_type
        BetterRecord::Current.user_type
      end

      def default_print
        column_names
      end

      def find_or_retry_by(*args)
        found = nil
        retries = 0
        begin
          raise ActiveRecord::RecordNotFound unless found = find_by(*args)
          return found
        rescue
          sleep retries += 1
          retry if (retries) < 5
        end
        found
      end

      def queue_adapter_inline?
        @@queue_adapter ||= Rails.application.config.active_job.queue_adapter
        @@queue_adapter == :inline
      end

      def table_name_defined?
        @table_name_defined ||= method_defined?(:table_name) || !!table_name.present?
      end

      def table_name_has_schema?
        @table_name_has_schema ||= (table_name =~ /\w+\.\w+/)
      end

      def table_name_without_schema
        @table_name_without_schema ||= (table_name =~ /\w+\.\w+/) ? table_name.split('.').last : table_name
      end

      def table_name_with_schema
        @table_name_without_schema ||= "#{table_schema}.#{table_name_without_schema}"
      end

      def table_schema
        @table_schema ||= table_name_has_schema? ? table_name.split('.').first : 'public'
      end

      def table_size
        BetterRecord::TableSize.unscoped.find_by(name: table_name_without_schema, schema: table_schema)
      end

      def transaction(*args)
        super(*args) do
          if BetterRecord::Current.user
            ip = BetterRecord::Current.ip_address ? "'#{BetterRecord::Current.ip_address}'" : 'NULL'

            ActiveRecord::Base.connection.execute <<-SQL
              CREATE TEMP TABLE IF NOT EXISTS
                "_app_user" (user_id integer, user_type text, ip_address inet);

              UPDATE
                _app_user
              SET
                user_id=#{BetterRecord::Current.user.id},
                user_type='#{current_user_type}',
                ip_address=#{ip};

              INSERT INTO
                _app_user (user_id, user_type, ip_address)
              SELECT
                #{BetterRecord::Current.user.id},
                '#{current_user_type}',
                #{ip}
              WHERE NOT EXISTS (SELECT * FROM _app_user);
            SQL
          end

          yield
        end
      end
    end

    def queue_adapter_inline?
      self.class.queue_adapter_inline?
    end

    %w(path url).each do |cat|
      self.__send__ :define_method, :"rails_blob_#{cat}" do |*args|
        Rails.application.routes.url_helpers.__send__ :"rails_blob_#{cat}", *args
      end
    end

    def purge(attached)
      attached.__send__ queue_adapter_inline? ? :purge : :purge_later
    end

    def boolean_columns
      self.class.boolean_columns
    end

    def default_print
      self.class.default_print
    end

    private
      # def table_name_has_schema?
      #   self.class.table_name_has_schema?
      # end
      #
      # def table_schema
      #   self.class.table_schema
      # end
      #
      # def table_name_without_schema
      #   self.class.table_name_without_schema
      # end

      def set_booleans
        self.class.boolean_columns.each do |nm|
          self.__send__("#{nm}=", __send__("#{nm}=", !!Boolean.parse(__send__ nm)))
        end
        true
      end
  end
end

ActiveRecord::Base.send(:include, BetterRecord::BaseExtensions)
