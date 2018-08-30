# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/number_helper'

module BetterRecord
  module ModelConcerns
    module HasProtectedPassword
      extend ActiveSupport::Concern

      included do
        unless self.const_defined?(:NON_DUPABLE_KEYS)
          NON_DUPABLE_KEYS = []
        end
      end

      module ClassMethods
        def has_protected_password(
          password_field: :password,
          password_validator: nil,
          min_image_size: nil,
          max_image_size: 500.kilobytes,
          **opts
        )
          # == Constants ============================================================
          self::NON_DUPABLE_KEYS |= %I[
            #{password_field}
            new_#{password_field}
            new_#{password_field}_confirmation
          ]

          # == Attributes ===========================================================
          attribute :"new_#{password_field}", :text
          attribute :"new_#{password_field}_confirmation", :text

          # == Extensions ===========================================================

          # == Relationships ========================================================

          # == Validations ==========================================================
          validate :"new_#{password_field}", :"require_#{password_field}_confirmation", if: :"new_#{password_field}?"

          if password_validator
            validate password_validator if :"new_#{password_field}?"
          end

          # == Scopes ===============================================================

          # == Callbacks ============================================================

          # == Boolean Class Methods ================================================

          # == Class Methods ========================================================

          # == Boolean Methods ======================================================

          # == Instance Methods =====================================================
          define_method password_field do
            self[password_field]
          end
          private password_field

          define_method :"#{password_field}=" do |value|
            write_attribute password_field, value
          end
          private :"#{password_field}="

          define_method :"require_#{password_field}_confirmation" do
            tmp_new_pwd = __send__ :"new_#{password_field}"
            tmp_new_confirmation = __send__ :"new_#{password_field}_confirmation"

            if tmp_new_pwd.present?
              if tmp_new_pwd != tmp_new_confirmation
                errors.add(:"new_#{password_field}", 'Password does not match confirmation')
              else
                self.password = new_password
              end
            end
          end
          private :"require_#{password_field}_confirmation"

        end
      end

    end
  end
end
