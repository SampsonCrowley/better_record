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
          shrink_later: false,
          **opts
        )
          # == Constants ============================================================

          # == Attributes ===========================================================
          attribute :"new_#{avatar_name}?", :boolean

          # == Extensions ===========================================================

          # == Relationships ========================================================
          has_one_attached :"last_#{avatar_name}"
          has_one_attached avatar_name

          # == Validations ==========================================================
          validate avatar_name, image_validator

          # == Scopes ===============================================================

          # == Callbacks ============================================================
          after_save :"cache_current_#{avatar_name}", if: :"new_#{avatar_name}?"

          # == Boolean Class Methods ================================================

          # == Class Methods ========================================================

          # == Boolean Methods ======================================================

          # == Instance Methods =====================================================
          define_method :"attach_#{avatar_name}" do |file, **options|
            __send__(avatar_name).attach(file, **options)
            __send__ image_validator
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
                begin
                  blob = __send__(avatar_name).blob
                  @copy_later = true
                  ResizeBlobImageJob.
                    __send__ (shrink_later ? :perform_later : :perform_now), {
                      model: self.class.to_s,
                      query: {id: self.id},
                      attachment: avatar_name,
                      backup_action: :"cache_current_#{avatar_name}",
                      options: shrink_large_image
                    }
                rescue
                  puts $!.message
                  puts $!.backtrace
                  return false
                end
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
            return unless __send__(avatar_name).attached?

            if valid_image_format && valid_image_size
              __send__(:"cache_current_#{avatar_name}") unless @copy_later
            else
              purge(__send__(avatar_name))
              __send__(:"load_last_#{avatar_name}") if __send__(:"last_#{avatar_name}").attached?
              false
            end
          end

          define_method :"cache_current_#{avatar_name}" do
            __send__ :"copy_#{avatar_name}"
          end

          define_method :"load_last_#{avatar_name}" do
            __send__ :"copy_#{avatar_name}", :"last_#{avatar_name}", avatar_name
          end

          define_method :"copy_#{avatar_name}" do |from = avatar_name, to = :"last_#{avatar_name}"|
            from = __send__ from
            to = __send__ to

            purge(to) if to.attached?

            tmp = Tempfile.new
            tmp.binmode
            tmp.write(from.download)
            tmp.flush
            tmp.rewind

            to.attach(io: tmp, filename: from.filename, content_type: from.content_type)
            tmp.close
            true
          end

        end
      end

    end
  end
end
