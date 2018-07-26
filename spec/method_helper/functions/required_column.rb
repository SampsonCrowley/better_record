module MethodHelper
  module Functions
    def required_column(factory_name, column_name, unique = false, &blk)
      describe column_name.to_s do
        let(:record) { build(factory_name) }

        it "is required" do
          record.__send__"#{column_name}=", nil
          expect(record.valid?).to be false
          expect(record.errors[column_name]).to include("can't be blank")
          expect { record.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
        end

        if unique
          it "must be unique" do
            expect(record.valid?).to be true
            expect(record.save).to be true

            dupped = record.dup
            expect(dupped.valid?).to be false
            expect(dupped.errors[column_name]).to include("has already been taken")
            expect(dupped.save).to be false

            record.destroy
            expect(dupped.valid?).to be true
            expect(dupped.save).to be true
            dupped.destroy
          end
        end

        instance_eval(&blk) if block_given?
      end
    end
  end
end
