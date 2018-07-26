FactoryBot.define do
  factory :better_record_table_size, class: 'BetterRecord::TableSize' do
    oid 1
    schema "MyString"
    name "MyString"
    apx_row_count 1.5
    total_bytes 1
    idx_bytes 1
    toast_bytes 1
    tbl_bytes 1
    total "MyText"
    idx "MyText"
    toast "MyText"
    tbl "MyText"
  end
end
