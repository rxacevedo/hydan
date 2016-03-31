# Class to simplify envelope encryption

module SecretsHelper
  module Crypto
    class EncryptionHelper

      def initialize
        @generator = OpenSSL::Cipher.new(Crypto::DEFAULT_CIPHER)
      end

      # Returns a JSON string containing the ciphertext (Base64 encoded)
      # and the encrypted data key used to encrypt it
      def encrypt(plaintext, symmetric_key, &block)
        unwrapped = block.call(plaintext) if block

        data_key = @generator.random_key
        key_cipher = Gibberish::AES.new(symmetric_key)
        data_cipher = Gibberish::AES.new(data_key)

        output = {
          'ciphertext' => JSON.parse(data_cipher.encrypt(unwrapped || plaintext)),
          'data_key' => Base64.strict_encode64(key_cipher.encrypt(data_key))
        }

        JSON.pretty_generate output
      end

      def encrypt_env_file(plaintext, symmetric_key)
        new_text = []
        plaintext.each_line do |l|
          k, v = l.match(Crypto::ENV_LINE_REGEX).captures
          enc_v = JSON.generate(JSON.parse(encrypt(v, symmetric_key)))
          new_text << "#{k}=#{enc_v}"
        end
        new_text
      end

    end
  end
end
