# frozen_string_literal: true

module BetterRecord
  module Rspec
    module Extensions
      def boolean_column(factory_name, column_name, default: false, keep_boolean_strictness: true)
        b_state = BetterRecord.strict_booleans || false
        
        describe column_name.to_s do
          let(:record) { build(*factory_name) }

          it "defaults to '#{default}'" do
            empty_record = record.class.new
            expect(empty_record.__send__ column_name).to be default
          end
          if keep_boolean_strictness
            it "parses to a #{b_state ? 'two' : 'three'}-state boolean" do
              [ nil, 0, 1, "true", "false", true, false ].each do |val|
                record.__send__"#{column_name}=", val

                expect(record.__send__ column_name).to eq(Boolean.__send__(b_state ? :strict_parse : :parse, val))
              end
            end
          else
            context 'loose booleans' do
              before do
                BetterRecord.strict_booleans = false
              end

              after do
                BetterRecord.strict_booleans = b_state
              end

              it "parses to a three-state boolean" do
                [ nil, 0, 1, "true", "false", true, false ].each do |val|
                  record.__send__"#{column_name}=", val

                  expect(record.__send__ column_name).to eq(Boolean.parse(val))
                end
              end
            end

            context 'strict booleans' do
              before do
                BetterRecord.strict_booleans = true
              end

              after do
                BetterRecord.strict_booleans = b_state
              end

              it "parses to a two-state boolean" do
                [ nil, 0, 1, "true", "false", true, false ].each do |val|
                  record.__send__"#{column_name}=", val

                  expect(record.__send__ column_name).to eq(Boolean.strict_parse(val))
                end
              end
            end
          end
        end
      end
    end
  end
end
