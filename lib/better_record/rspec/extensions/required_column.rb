# frozen_string_literal: true

module BetterRecord
  module Rspec
    module Extensions
      def required_column(factory_name, column_name, unique = false, in_app_only = false, &blk)
        describe column_name.to_s do
          let(:record) { build(factory_name) }

          it "is required" do
            record.__send__"#{column_name}=", nil
            expect(record.valid?).to be false
            expect(record.errors[column_name]).to include("can't be blank")
            unless in_app_only
              expect { record.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
            end
          end

          if unique
            it "must be unique" do
              expect(record.valid?).to be true
              expect(record.save).to be true

              dupped = nil

              begin
                dupped = record.dup(true)
              rescue ArgumentError
                dupped = record.dup
              end

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
end
