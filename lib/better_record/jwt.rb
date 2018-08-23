# frozen_string_literal: true

require 'jwt'
require 'jwe'
require 'openssl'

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
      protected
        def check_user
          if logged_in?
            begin
              data = current_user_session_data
              if  !data[:created_at] ||
                  (data[:created_at].to_i > 14.days.ago.to_i)
                if user = session_class.find_by(session_column => data[:user_id])
                  session[:current_user] = create_jwt(user, data) if data[:created_at] < 1.hour.ago
                  set_user(user)
                else
                  throw 'User Not Found'
                end
              else
                throw 'Token Expired'
              end
            rescue
              session.delete(:current_user)
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
            created_at: Time.now.to_i
          }
          BetterRecord::JWT.encode(data.merge(additional_headers.except(*data.keys)))
        end

        def create_session_from_certificate(cert)
          user = (certificate_session_class || session_class).
          find_by(certificate_session_column => cert.clean_certificate)

          if user
            if  certificate_session_user_method &&
                user.respond_to?(certificate_session_user_method)
              user = user.__send__(certificate_session_user_method)
            end

            session[:current_user] = create_jwt(user, { has_certificate: true })
          end
        end

        def current_user
          BetterRecord::Current.user || check_user
        end

        def current_user_session_data
          logged_in? ? JWT.decode(session[:current_user]).deep_symbolize_keys : {}
        end

        def logged_in?
          session[:current_user].present?
        end

        def set_user(user)
          BetterRecord::Current.set(user, request.remote_ip)
        end
    end
  end
end
