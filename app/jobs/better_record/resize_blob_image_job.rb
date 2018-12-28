module BetterRecord
  class ResizeBlobImageJob < ApplicationJob
    queue_as :default

    def perform(**params)
      if record = params[:model].constantize.find_by(params[:query].deep_symbolize_keys)
        blob = record.__send__(params[:attachment]).blob
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
        blob.purge_later
        params[:backup_action].present? && record.__send__(params[:backup_action])
      end
    end
  end
end
