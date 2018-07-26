require "application_system_test_case"

module BetterRecord
  class TableSizesTest < ApplicationSystemTestCase
    setup do
      @table_size = better_record_table_sizes(:one)
    end

    test "visiting the index" do
      visit table_sizes_url
      assert_selector "h1", text: "Table Sizes"
    end
  end
end
