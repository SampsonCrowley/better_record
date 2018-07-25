module AuditableTable
  extend ActiveSupport::Concern

  def audit_table(table_name, rows = nil, query_text = nil, skip_columns = nil)
    reversible do |d|
      d.up do
        if(rows && rows.is_a?(Array))
          skip_columns = rows
          rows = true
          query_text = true
        end

        if(rows.nil?)
          execute "SELECT audit.audit_table('#{table_name}');"
        else
          rows = !!rows ? 't' : 'f'
          query_text = !!query_text ? 't' : 'f'
          skip_columns = skip_columns.present? ? "'{#{skip_columns.join(',')}}'" : 'ARRAY[]'
          execute "SELECT audit.audit_table('#{table_name}', BOOLEAN '#{rows}', BOOLEAN '#{query_text}', #{skip_columns}::text[]);"
        end
      end

      d.down do
        execute "DROP TRIGGER audit_trigger_row ON #{table_name};"
        execute "DROP TRIGGER audit_trigger_stm ON #{table_name};"
      end
    end
  end
end
