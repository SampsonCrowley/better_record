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
              if  !data[:created_at] ||
                  (data[:created_at].to_i > 14.days.ago.to_i)
                if user = session_class.find_by(session_column => data[:user_id])
                  self.current_token = create_jwt(user, data) if data[:created_at].to_i < 1.hour.ago.to_i
                  set_user(user)
                else
                  throw 'User Not Found'
                end
              else
                throw 'Token Expired'
              end
            rescue
              p $!.message
              puts $!.message.backtrace.first(10)
              
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
            created_at: Time.now.to_i
          }
          BetterRecord::JWT.encode(data.merge(additional_headers.except(*data.keys)))
        end

        def create_session_from_certificate(cert)
          u_class = (certificate_session_class || session_class)
          user = u_class.where.not(certificate_session_column => nil)

          if certificate_is_hashed
            user = user.find_by("#{certificate_session_column} = crypt(?, #{certificate_session_column})", cert.clean_certificate)
          else
            user = user.find_by(certificate_session_column => cert.clean_certificate)
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

        def current_user
          BetterRecord::Current.user || check_user
        end

        def current_user_session_data
          logged_in? ? JWT.decode(current_token).deep_symbolize_keys : {}
        end

        def logged_in?
          current_token.present? ||
          (
            certificate_header &&
            header_hash[certificate_header].present? &&
            create_session_from_certificate(header_hash[certificate_header])
          )
        end

        def current_token
          if use_bearer_token
            @current_token ||= authenticate_with_http_token do |token, **options|
              token
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
          response.set_header("AUTH_TOKEN", current_token)
        end

        def set_user(user)
          BetterRecord::Current.set(user, get_ip_address)
        end

        def get_ip_address
          header_hash[:HTTP_X_REAL_IP] ||
          header_hash[:HTTP_CLIENT_IP] ||
          request.remote_ip
        end
    end
  end
end
