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
            BetterRecord::AttachmentValidation.delete_invalid
            begin
              opts = { name: image_validator, attachment_id: reloaded_record&.__send__(avatar_name)&.attachment&.id, ran: ran }
              AttachmentValidation.create!(opts) if opts[:attachment_id]
            rescue
              if ran && $!.is_a?(PG::UniqueViolation) && !__send__(:"#{avatar_name}_validation_record").ran
                __send__(:"#{avatar_name}_validation_record").update(ran: true)
              end
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
                  shrink_wait_time  ?
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
            raise "Uh Oh" unless __send__(:"#{avatar_name}_validation_ran?", true)

            if valid_image_format && valid_image_size
              self.__send__(:"shrinking_#{avatar_name}") ||
              __send__(:"cache_current_#{avatar_name}")
              true
            else
              __send__(:"load_last_#{avatar_name}")
              false
            end
          end

          define_method :"check_#{image_validator}" do |*args|
            return true  if self.id.blank? || !reloaded_record&.__send__(avatar_name).attached?
            __send__(image_validator) unless __send__(:"#{avatar_name}_validation_ran?", true)
          end

          define_method :"cache_current_#{avatar_name}" do
            __send__ :"copy_#{avatar_name}"
          end

          define_method :"load_last_#{avatar_name}" do
            __send__ :"copy_#{avatar_name}", :"last_#{avatar_name}", avatar_name
            __send__(:"create_#{avatar_name}_validation", true)
          end

          define_method :"copy_#{avatar_name}" do |from = avatar_name, to = :"last_#{avatar_name}"|
            puts "COPYING #{from} TO #{to}"
            # begin
            # rescue
            #   puts $!.message
            #   puts $!.backtrace
            # end

            from_attachment = __send__ from
            to_attachment   = __send__ to


            if from_attachment.attached?
              return true if from_attachment.attachment&.blob_id == to_attachment.attachment&.blob_id
              delete_attachment to
              to_attachment.attach from_attachment.blob
            else
              delete_attachment to
            end
          end

          define_method :delete_attachment do |att_name = avatar_name, now = false|
            begin
              atchd = __send__ att_name
              if atchd.attachment
                atchd_blob = atchd.blob
                atchd.detach
                atchd_blob&.__send__ now ? :purge : :purge_later
              end
            rescue Exception
            end
          end

          define_method :reloaded_record do
            self.class.find_by(id: self.id)
          end
        end
      end
    end
  end
end
