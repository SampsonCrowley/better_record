# frozen_string_literal: true

module BetterRecord
  module Uploadable
    extend ActiveSupport::Concern

    def whitelisted_upload_params
      params.require(:upload).permit(:file, :staff_id)
    end

    def csv_upload(job, whitelisted_params, upload_key, prefix, job_sym = :staff_id, redirecting = false)
      p whitelisted_params
      uploaded = whitelisted_params[upload_key]
      job_id = whitelisted_params[job_sym]
      @file_stats = {
        name: uploaded.original_filename,
        "mime-type" => uploaded.content_type,
        size: view_context.number_to_human_size(uploaded.size)
      }
      if verify_file(whitelisted_params, upload_key)
        File.open(Rails.root.join('public', 'import_csv', "#{prefix}_#{Time.now.to_i}#{rand(1000..100000)}.csv"), 'wb') do |file|
          uploaded = BetterRecord::Encoder.new(uploaded.read).to_utf8
          file.write(uploaded)
          job.perform_later file.path, job_id, @file_stats[:name]
        end
        if redirecting
          flash[:success] ||= []
          flash[:success] << 'File Uploaded'
        else
          flash.now[:success] ||= []
          flash.now[:success] << 'File Uploaded'
        end
        return true
      else
        msg = [
          'something went wrong',
          'Only csv files with the correct headers are supported',
          "content type: #{whitelisted_params[upload_key].content_type}", "file name: #{whitelisted_params[upload_key].original_filename}"
        ]

        if redirecting
          flash[:danger] = msg
        else
          flash.now[:danger] = msg

          render :show
        end
      end
    end

    private
      def verify_file(whitelisted_params, upload_key)
        correct_mime_type(whitelisted_params, upload_key) && /\.csv/ =~ whitelisted_params[upload_key].original_filename
      end

      def correct_mime_type(whitelisted_params, upload_key)
        [
          "text/csv",
          "text/plain",
          "application/vnd.ms-excel",
          "text/x-csv",
          "application/csv",
          "application/x-csv",
          "text/csv",
          "text/comma-separated-values",
          "text/x-comma-separated-values"
        ].any? {|mime| mime == whitelisted_params[upload_key].content_type}
      end
  end
end
