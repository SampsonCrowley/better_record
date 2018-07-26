module MethodHelper
  module Functions
    def has_valid_factory(factory_name, count = 10)
      it "has a valid factory" do
        records = []
        count = (count.to_i == 0) ? 1 : count.to_i
        count.times do
          test_factory = build(factory_name)
          unless test_factory.valid?
            puts test_factory.errors.full_messages
          end
          expect(test_factory.valid?).to be true
          expect(test_factory.save).to be true
          records << test_factory
        end
        records.each {|f| f.destroy}
      end
    end
  end
end
