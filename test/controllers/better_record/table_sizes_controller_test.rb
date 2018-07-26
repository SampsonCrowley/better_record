require 'test_helper'

module BetterRecord
  class TableSizesControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @table_size = better_record_table_sizes(:one)
    end

    test "should get index" do
      get table_sizes_url
      assert_response :success
    end

    test "should get new" do
      get new_table_size_url
      assert_response :success
    end

    test "should create table_size" do
      assert_difference('TableSize.count') do
        post table_sizes_url, params: { table_size: {  } }
      end

      assert_redirected_to table_size_url(TableSize.last)
    end

    test "should show table_size" do
      get table_size_url(@table_size)
      assert_response :success
    end

    test "should get edit" do
      get edit_table_size_url(@table_size)
      assert_response :success
    end

    test "should update table_size" do
      patch table_size_url(@table_size), params: { table_size: {  } }
      assert_redirected_to table_size_url(@table_size)
    end

    test "should destroy table_size" do
      assert_difference('TableSize.count', -1) do
        delete table_size_url(@table_size)
      end

      assert_redirected_to table_sizes_url
    end
  end
end
