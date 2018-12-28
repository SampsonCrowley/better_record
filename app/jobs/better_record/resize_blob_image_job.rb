module BetterRecord
  class ResizeBlobImageJob < ApplicationJob
    queue_as :default

    def perform(**params)
      begin
        if record = params[:model].constantize.find_by(params[:query].deep_symbolize_keys)
          blob = record.__send__(params[:attachment].to_sym).blob
          tmp = Tempfile.new
          tmp.binmode
          tmp.write(blob.service.download(blob.variant(params[:options]).processed.key))
          tmp.flush
          tmp.rewind
          record.__send__(params[:attachment]).attach(
            io: tmp,
            filename: blob.filename,
            content_type: blob.content_type
          )
          begin
            blob.purge_later
          rescue
          end
          params[:backup_action].present? && record.__send__(params[:backup_action].to_sym)
        end
        true
      rescue
        p $!.to_s
        p $!.message
        p $!.backtrace.first(25)
        return false
      end
    end
  end
end
