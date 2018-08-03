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
  end
end
