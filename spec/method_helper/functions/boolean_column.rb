module MethodHelper
  module Functions
    def boolean_column(factory_name, column_name, default_val = false)
      describe column_name.to_s do
        let(:record) { build(factory_name) }

        it "cannot be nil in the database" do
          stubbed = record.dup
          allow(stubbed).to receive(:set_booleans)

          stubbed.__send__"#{column_name}=", nil
          expect(stubbed.valid?).to be false
          expect(stubbed.errors[column_name]).to include("must be true or false")
          expect { stubbed.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
        end

        it "defaults to '#{default_val}'" do
          empty_record = record.class.new
          expect(empty_record.__send__ column_name).to be default_val
        end

        it "will parse to boolean on save" do
          record.__send__"#{column_name}=", nil
          record.save
          expect(record.__send__ column_name).to be false

          record.__send__"#{column_name}=", 0
          record.save
          expect(record.__send__ column_name).to be false

          record.__send__"#{column_name}=", 'false'
          record.save
          expect(record.__send__ column_name).to be false

          record.__send__"#{column_name}=", 1
          record.save
          expect(record.__send__ column_name).to be true

          record.__send__"#{column_name}=", 'asdf'
          record.save
          expect(record.__send__ column_name).to be true

          record.__send__"#{column_name}=", 'true'
          record.save
          expect(record.__send__ column_name).to be true

          record.destroy
        end
      end
    end
  end
end
