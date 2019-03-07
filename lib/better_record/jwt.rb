# frozen_string_literal: true

require 'jwt'
require 'jwe'
require 'openssl'
require 'active_support/concern'

module BetterRecord
  class JWT
    CHARACTERS = [*('a'..'z'), *('A'..'Z'), *(0..9).map(&:to_s), *'!@#$%^&*()'.split('')]
    DEFAULT_OPTIONS = { enc:  'A256GCM', alg: 'dir', zip: 'DEF' }

    class << self
      def gen_encryption_key
        SecureRandom.random_bytes(32)
      end

      def encryption_key
        @encryption_key ||= gen_encryption_key
      end

      def encryption_key=(key)
        @encryption_key = key || gen_encryption_key
      end

      def gen_signing_key(length = 50)
        (0...length).map { CHARACTERS[rand(CHARACTERS.length)] }.join
      end

      def signing_key
        @signing_key ||= gen_signing_key
      end

      def signing_key=(key)
        @signing_key = key || gen_signing_key
      end

      def encrypt_options
        @encrypt_options ||= DEFAULT_OPTIONS
      end

      def encrypt_options=(options)
        @encrypt_options = options || DEFAULT_OPTIONS
      end

      def encode(payload, sig_key = nil, enc_key = nil, options = nil)
        ::JWE.encrypt ::JWT.encode(payload, (sig_key || signing_key), 'HS512'), (enc_key || encryption_key), (options || encrypt_options)
      end

      alias_method :create, :encode
      alias_method :encrypt, :encode
      alias_method :inflate, :encode

      def decode(payload, sig_key = nil, enc_key = nil)
        ::JWT.decode(::JWE.decrypt(payload, (enc_key || encryption_key)), (sig_key || signing_key), true, algorithm: 'HS512')[0]
      end

      alias_method :read, :decode
      alias_method :decrypt, :decode
      alias_method :deflate, :decode
    end

    module ControllerMethods
      extend ActiveSupport::Concern

      included do
        include BetterRecord::InjectMethods
        include ActionController::HttpAuthentication::Token::ControllerMethods if BetterRecord.use_bearer_token
      end

      protected
        def check_user
          if logged_in?
            begin
              data = current_user_session_data
              if data[:device_id] == requesting_device_id
                if  !data[:created_at] ||
                    (data[:created_at].to_i > 14.days.ago.to_i)
                  if user = session_class.find_by(session_column => data[:user_id])
                    self.current_token = create_jwt(user, data) if data[:created_at].to_i < 1.hour.ago.to_i
                    set_user(user)
                  else
                    raise 'User Not Found'
                  end
                else
                  raise 'Token Expired'
                end
              else
                raise "Device Does Not Match - #{data[:device_id]} || #{requesting_device_id}"
              end
            rescue
              p $!.message
              puts $!.backtrace.first(10)

              self.current_token = nil
              BetterRecord::Current.drop_values
            end
          end

          BetterRecord::Current.user || false
        end

        def create_jwt(user, additional_headers = {})
          additional_headers = {} unless additional_headers && additional_headers.is_a?(Hash)
          data = nil
          data = session_data ? session_data.call(user) : {
            user_id: user.__send__(session_column),
            created_at: Time.now.to_i,
            device_id: requesting_device_id
          }
          BetterRecord::JWT.encode(data.merge(additional_headers.except(*data.keys)))
        end

        def create_session_from_certificate(cert)
          u_class = (certificate_session_class || session_class)
          user = u_class.where.not(certificate_session_column => nil)

          if certificate_is_hashed
            user = user.find_by("#{certificate_session_column} = crypt(?, #{certificate_session_column})", br_get_clean_cert(cert))
          else
            user = user.find_by(certificate_session_column => br_get_clean_cert(cert))
          end

          if user
            if  certificate_session_user_method &&
                user.respond_to?(certificate_session_user_method)
              user = user.__send__(certificate_session_user_method)
            end

            self.current_token = create_jwt(user, { has_certificate: true })
            set_user(user)
          end
        end

        def br_get_clean_cert(certificate)
          ensure_is_real_value(
            certificate_cleaning_send_as_arg ?
              self.__send__(certificate_cleaning_method, certificate) :
              (
                certificate_cleaning_method.present? ?
                  certificate.__send__(certificate_cleaning_method) :
                  certificate
              ).presence
          )
        end

        def current_user
          BetterRecord::Current.user || check_user
        end

        def current_user_session_data
          logged_in? ? JWT.decode(current_token).deep_symbolize_keys : {}
        rescue
          {}
        end

        def has_correct_origin?
          true
        end

        def requesting_device_id
          @requesting_device_id = (session[:requesting_device_id] ||= SecureRandom.uuid)
        end

        def logged_in?
          current_token.present? || certificate_session_exists?
        end

        def certificate_string
          @certificate_string ||= certificate_header &&
            header_hash[certificate_header].presence
        end

        def certificate_session_exists?
          !!(
            certificate_string &&
            has_correct_origin? &&
            create_session_from_certificate(certificate_string)
          )
        end

        def current_token
          if use_bearer_token
            @current_token ||= authenticate_with_http_token do |token, **options|
              decrypt_token(token, options).presence
            end
          else
            @current_token ||= session[:current_user]
          end
        end

        def current_token=(value)
          @current_token = value
          if use_bearer_token
            set_auth_header
          else
            if value.blank?
              session.delete(:current_user)
            else
              session[:current_user] = value
            end
          end
          @current_token
        end

        def header_hash
          @header_hash ||= request.headers.to_h.deep_symbolize_keys
        end

        def set_auth_header
          response.set_header("AUTH_TOKEN", encrypt_token) if current_token.present?
        end

        def decrypt_token(t, **options)
          ensure_is_real_value(
            token_send_as_arg ?
              __send__(token_decryption_method, t, options) :
              (
                token_decryption_method.present? ?
                  t.__send__(token_decryption_method) :
                  t
              ).presence
          )
        end

        def encrypt_token
          ensure_is_real_value(
            token_send_as_arg ?
              __send__(token_encryption_method, current_token) :
              (
                token_encryption_method.present? ?
                  current_token.__send__(token_encryption_method) :
                  current_token
              ).presence
          )
        end


        def set_user(user)
          BetterRecord::Current.set(user, get_ip_address)
        end

        def get_ip_address
          header_hash[:HTTP_X_REAL_IP] ||
          header_hash[:HTTP_CLIENT_IP] ||
          request.remote_ip
        end

        def ensure_is_real_value(value)
          (Boolean.parse(value) && (value != "nil")) ?
            value :
            nil
        end
    end
  end
end
