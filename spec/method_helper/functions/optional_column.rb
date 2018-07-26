module MethodHelper
  module Functions
    def optional_column(factory_name, column_name, &blk)
      describe column_name.to_s do
        let(:record) { build(factory_name) }

        it "is optional" do
          record.__send__"#{column_name}=", nil
          expect(record.valid?).to be true
          expect(record.errors[column_name]).to be_empty
        end

        instance_eval(&blk) if block_given?
      end
    end
  end
end
