# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/number_helper'
require 'active_storage/engine'

module BetterRecord
  module ModelConcerns
    module HasValidatedAvatar
      extend ActiveSupport::Concern

      module ClassMethods
        def has_validated_avatar(
          avatar_name: :avatar,
          image_validator: :valid_image,
          min_image_size: nil,
          max_image_size: 500.kilobytes,
          shrink_large_image: false,
          shrink_wait_time: 1.minute,
          **opts
        )
          # == Constants ============================================================

          # == Attributes ===========================================================
          attribute :"shrinking_#{avatar_name}", :boolean, default: false

          # == Extensions ===========================================================

          # == Relationships ========================================================
          has_one_attached :"last_#{avatar_name}"
          has_one_attached avatar_name

          # == Validations ==========================================================
          validate avatar_name, :"check_#{image_validator}"

          # == Scopes ===============================================================

          # == Callbacks ============================================================
          after_commit :"check_#{image_validator}", if: :"#{avatar_name}_attached?", on: %i[ create update ]

          # == Boolean Class Methods ================================================

          # == Class Methods ========================================================

          # == Boolean Methods ======================================================
          define_method :"#{avatar_name}_attached?" do
            __send__(avatar_name).attached?
          end

          define_method :"#{avatar_name}_validation_ran?" do |rld=false|
            !!__send__(:"#{avatar_name}_validation_record", !!rld)&.ran
          end

          # == Instance Methods =====================================================
          define_method :"attach_#{avatar_name}" do |*args, **options|
            __send__(avatar_name).attach(*args, **options)
            __send__ image_validator
          end

          define_method :"create_#{avatar_name}_validation" do |ran=false|
            begin
              AttachmentValidation.create!(name: image_validator, attachment_id: __send__(avatar_name).id, ran: ran)
            rescue
              __send__(:"#{avatar_name}_validation_record").update(ran: true) if $!.is_a?(PG::UniqueViolation) && ran && !__send__(:"#{avatar_name}_validation_record").ran
            end
            __send__(:"#{avatar_name}_validation_record")
          end

          define_method :"#{avatar_name}_validation_record" do |rld=false|
            (!rld && instance_variable_get(:"@#{avatar_name}_record")) ||
            instance_variable_set(
              :"@#{avatar_name}_record",
              AttachmentValidation.find_by(attachment_id: __send__(avatar_name).id, name: image_validator)
            )
          end

          define_method :valid_image_format do
            unless __send__(avatar_name).blob.content_type.start_with? 'image/'
              errors.add(avatar_name, 'is not an image file')
              return false
            end
            true
          end

          define_method :valid_image_size do
            if max_image_size && __send__(avatar_name).blob.byte_size > max_image_size
              if shrink_large_image.present?
                puts "\nSHRINKING\n"
                self.__send__ :"shrinking_#{avatar_name}=", true
                (
                  shrink_wait_time ?
                  ResizeBlobImageJob.set(wait: shrink_wait_time) :
                  ResizeBlobImageJob
                ).perform_later(
                  model: self.class.to_s,
                  query: {id: self.id},
                  attachment: avatar_name.to_s,
                  options: shrink_large_image
                )
                true
              else
                errors.add(avatar_name, "is too large, maximum #{ActiveSupport::NumberHelper.number_to_human_size(max_image_size)}")
                return false
              end
            elsif min_image_size && __send__(avatar_name).blob.byte_size < min_image_size
              errors.add(avatar_name, "is too small, minimum #{ActiveSupport::NumberHelper.number_to_human_size(min_image_size)}")
              return false
            end
            true
          end

          define_method :valid_image do
            return true unless __send__(avatar_name).attached?
            __send__(:"create_#{avatar_name}_validation", true)

            if valid_image_format && valid_image_size
              self.__send__(:"shrinking_#{avatar_name}") ||
              reloaded_record.__send__(:"cache_current_#{avatar_name}")
            else
              r = reloaded_record.__send__(avatar_name)
              begin
                r.purge_later if r.attached?
              rescue Exception
              end
              __send__(:"load_last_#{avatar_name}") if __send__(:"last_#{avatar_name}").attached?
              false
            end
          end

          define_method :"check_#{image_validator}" do |*args|
            return true unless __send__(avatar_name).attached?
            __send__(image_validator) unless __send__(:"#{avatar_name}_validation_ran?", true)
          end

          define_method :"cache_current_#{avatar_name}" do
            reloaded_record.__send__ :"copy_#{avatar_name}"
          end

          define_method :"load_last_#{avatar_name}" do
            reloaded_record.__send__ :"copy_#{avatar_name}", :"last_#{avatar_name}", avatar_name
          end

          define_method :"copy_#{avatar_name}" do |from = avatar_name, to = :"last_#{avatar_name}"|
            puts "COPYING #{from} TO #{to}"
            from_attachment = __send__ from
            to_attachment = __send__ to

            if to_attachment.attached?
              begin
                atch = ActiveStorage::Attachment.find_by(to_attachment.id)
                atch&.purge_later
              rescue Exception
                begin
                  ActiveStorage::Attachment.find_by(to_attachment.id).destroy
                rescue Exception
                end
              end
            end

            if from_attachment.attached?
              tmp = Tempfile.new
              tmp.binmode
              tmp.write(from_attachment.download)
              tmp.flush
              tmp.rewind

              r = reloaded_record
              from_attachment = r.__send__ from
              to_attachment = r.__send__ to

              to_attachment.attach(io: tmp, filename: from_attachment.filename, content_type: from_attachment.content_type)
              tmp.close
            end
            true
          end

          define_method :reloaded_record do
            self.class.find_by(id: self.id)
          end

        end
      end

    end
  end
end
