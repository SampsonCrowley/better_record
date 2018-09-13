# frozen_string_literal: true

require 'active_support/concern'

module BetterRecord
  module ModelConcerns
    module HasProtectedPassword
      extend ActiveSupport::Concern

      module ClassMethods
        def has_protected_password(
          password_field: :password,
          password_validator: nil,
          confirm: true,
          **opts
        )
          # == Constants ============================================================
          og_dup_arr = []

          if (
            self.const_defined?(:NON_DUPABLE_KEYS) &&
            (
              self.const_get(:NON_DUPABLE_KEYS).is_a?(Array) ||
              self.const_belongs_to_parent?(:NON_DUPABLE_KEYS)
            )
          )
            og_dup_arr = [*self.const_get(:NON_DUPABLE_KEYS)]
            self.__send__ :remove_const, :NON_DUPABLE_KEYS unless self.const_belongs_to_parent?(:NON_DUPABLE_KEYS)
          end

          unless self.const_defined?(:NON_DUPABLE_KEYS)
            self.__send__ :const_set, :NON_DUPABLE_KEYS, Set[]
          end

          self::NON_DUPABLE_KEYS.merge(%I[
            #{password_field}
            new_#{password_field}
            new_#{password_field}_confirmation
            clear_#{password_field}
          ])

          # == Attributes ===========================================================
          attribute :"new_#{password_field}", :text
          attribute :"new_#{password_field}_confirmation", :text
          attribute :"clear_#{password_field}", :text

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

          define_method :"clear_#{password_field}=" do |value|
            if value && (value.to_sym == :clear)
              __send__ :"#{password_field}=", (self.persisted? ? 'CLEAR_EXISTING_PASSWORD_FOR_ROW' : nil)
              __send__ :"new_#{password_field}=", nil
              __send__ :"new_#{password_field}_confirmation=", nil
            end
            true
          end

          if confirm
            define_method :"require_#{password_field}_confirmation" do
              tmp_new_pwd = __send__ :"new_#{password_field}"
              tmp_new_confirmation = __send__ :"new_#{password_field}_confirmation"

              if tmp_new_pwd.present?
                if tmp_new_pwd != tmp_new_confirmation
                  errors.add(:"new_#{password_field}", 'does not match confirmation')
                else
                  self.__send__ :"#{password_field}=", tmp_new_pwd
                end
              end
            end
          else
            define_method :"require_#{password_field}_confirmation" do
              tmp_new_pwd = __send__ :"new_#{password_field}"

              if tmp_new_pwd.present?
                self.__send__ :"#{password_field}=", tmp_new_pwd
              end
            end
          end
          private :"require_#{password_field}_confirmation"

        end
      end

    end
  end
end
