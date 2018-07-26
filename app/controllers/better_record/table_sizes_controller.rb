require_dependency "better_record/application_controller"

module BetterRecord
  class TableSizesController < ApplicationController
    before_action :set_table_size, only: [:show]

    # GET /table_sizes
    def index
      TableSize.reload_data if Boolean.parse(params[:reload])
      @table_sizes = TableSize.all
    end

    # GET /table_sizes/1
    def show
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_table_size
        @table_size = TableSize.find_by(oid: params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def table_size_params
        params.fetch(:table_size, {})
      end
  end
end
