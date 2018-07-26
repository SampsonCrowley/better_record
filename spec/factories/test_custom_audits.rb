FactoryBot.define do
  factory :test_custom_audit do
    test_text "MyText"
    test_date "2018-07-25"
    test_time "2018-07-25 17:30:07"
    test_skipped_column "MyText"
  end
end
