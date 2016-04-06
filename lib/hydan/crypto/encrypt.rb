# Class to simplify envelope encryption

require 'openssl'

module Hydan
  module Crypto
    class EncryptionHelper

      def initialize(master_key)
        @master_key = master_key
        @generator = OpenSSL::Cipher.new(Crypto::DEFAULT_CIPHER)
        @generator.encrypt
      end

      # Returns a JSON string containing the ciphertext (Base64 encoded)
      # and the encrypted data key used to encrypt it
      def encrypt(plaintext)
        data_key = @generator.random_key
        key_cipher = Gibberish::AES.new(@master_key)
        data_cipher = Gibberish::AES.new(data_key)
        output = {
          'ciphertext' => JSON.parse(data_cipher.encrypt(plaintext)),
          'data_key' => Base64.strict_encode64(key_cipher.encrypt(data_key))
        }
        JSON.pretty_generate output
      end

      # Encrypts a file and returns the encrypted data key
      # that was generated for the file. File encryption
      # uses a different library method that is basically
      # line-by-line read-encrypt-write mechanism.
      def encrypt_file(in_file, out_file)
        data_key = @generator.random_key
        key_cipher = Gibberish::AES::CBC.new(@master_key)
        data_cipher = Gibberish::AES::CBC.new(data_key)
        # The return value for this is Base64-encoded by default,
        # we're overriding it here to later #strict_encode64 it.
        encrypted_data_key = key_cipher.encrypt(data_key, binary: true)
        data_key = nil # Scrub from memory as soon as feasible
        data_cipher.encrypt_file(in_file, out_file)
        encrypted_data_key
      end
      # TODO: This may be better suited for the plaintext
      # encryption entrypoint (STDIN or --plaintext flag)
      def encrypt_env_formatted(plaintext)
        new_text = []
        plaintext.each_line do |l|
          k, v = l.match(Hydan::IO::ENV_LINE_REGEX).captures
          enc_v = JSON.generate(JSON.parse(encrypt(v)))
          new_text << "#{k}=#{enc_v}"
        end
        new_text
      end
    end
  end
end
