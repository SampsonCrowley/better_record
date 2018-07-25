module BetterRecord
  class Base < ActiveRecord::Base
    self.abstract_class = true

    # == Constants ============================================================

    # == Attributes ===========================================================

    # == Extensions ===========================================================

    # == Relationships ========================================================
    if (ha = BetterRecord.has_audits_by_default)
      has_many :audits,
        class_name: 'BetterRecord::Audit',
        primary_type: :table_name,
        foreign_key: :row_id,
        foreign_type: :table_name,
        as: :audits
    end

    # == Validations ==========================================================
    before_validation :set_booleans

    # == Scopes ===============================================================

    # == Callbacks ============================================================

    # == Class Methods ========================================================
    def self.boolean_columns
      []
    end

    def self.column_comments(prefix = '')
      longest_name = 0
      column_names.each {|nm| longest_name = nm.length if nm.length > longest_name}
      longest_name += 1
      str = ''
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

    def self.default_print
      column_names
    end

    def self.find_or_retry_by(*args)
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

    def self.queue_adapter_inline?
      @@queue_adapter ||= Rails.application.config.active_job.queue_adapter
      @@queue_adapter == :inline
    end

    def self.table_name_has_schema?
      @@table_name_has_schema ||= (table_name =~ /\w+\.\w+/)
    end

    def self.table_name_without_schema
      @@table_name_without_schema ||= (table_name =~ /\w+\.\w+/) ? table_name.split('.').last : table_name
    end

    def self.table_schema
      @@table_schema ||= table_name_has_schema? ? table_name.split('.').first : 'public'
    end

    def self.table_size
      BetterRecord::TableSize.unscoped.find_by(name: table_name_without_schema, schema: table_schema)
    end

    def self.transaction(*args)
      super(*args) do
        if Current.user
          ip = Current.ip_address ? "'#{Current.ip_address}'" : 'NULL'

          ActiveRecord::Base.connection.execute <<-SQL
            CREATE TEMP TABLE IF NOT EXISTS
              "_app_user" (user_id integer, user_type text, ip_address inet);

            UPDATE
              _app_user
            SET
              user_id=#{Current.user.id},
              user_type='#{Current.user.class.to_s}',
              ip_address=#{ip};

            INSERT INTO
              _app_user (user_id, user_type, ip_address)
            SELECT
              #{Current.user.id},
              '#{Current.user.class.to_s}',
              #{ip}
            WHERE NOT EXISTS (SELECT * FROM _app_user);
          SQL
        end

        yield
      end
    end

    # == Instance Methods =====================================================
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
