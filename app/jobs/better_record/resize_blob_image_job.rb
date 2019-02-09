module BetterRecord
  class ResizeBlobImageJob < ApplicationJob
    queue_as :default

    def perform(**params)
      begin
        if record = params[:model].constantize.find_by(params[:query].deep_symbolize_keys)
          name = params[:attachment].to_sym
          blob = record.__send__(name).blob
          tmp = Tempfile.new
          tmp.binmode
          tmp.write(blob.service.download(blob.variant(blob.filename.to_s =~ /-resized/ ? {resize: '70%'} : params[:options]).processed.key))
          tmp.flush
          tmp.rewind

          blob.analyze if blob.filename.to_s =~ /-resized/

          attachment = ActionDispatch::Http::UploadedFile.new(
            tempfile: tmp,
            filename: blob.filename.to_s.sub(/(\.[^.]*)$/, '-resized\1').sub(/(-resized)+/, '-resized'),
            type: blob.content_type
          )

          record.
            __send__ :delete_attachment, name, true

          record.
            reload.__send__(params[:attachment]).
            reload.attach(attachment)

          puts "\n\nSAVED IMAGE\n\n"
          begin
            if params[:backup_action].present?
              record.class.find_by(params[:query]).__send__(params[:backup_action].to_sym)
            end
          rescue
            puts "BACKUP ACTION FAILED"
            puts $!.message
            puts $!.backtrace
          end
          begin
            puts "\n\n PURGING BLOB \n\n"
            puts "blob exists? #{blob = ActiveStorage::Blob.find_by(id: blob.id).present?}"
            blob.purge if blob.present?
            puts "\n\n FINISHED PURGING BLOB \n\n"
          rescue
          end
        else
          raise ActiveRecord::RecordNotFound
        end
        return true
      rescue
        "ERROR RESIZING IMAGE"
        puts $!.message
        puts $!.backtrace.first(25)
        return false
      end
    end
  end
end
