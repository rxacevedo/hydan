# Class to simplify KMS decryption interface

module SecretsHelper
  module KMS
    class DecryptionHelper

      ENV_LINE_REGEX = /(.*?)=(.*)/

      def initialize
        @kms = Aws::KMS::Client.new
      end

      # Decrypts a JSON object
      # @return [String]
      def decrypt(json)
        input_hash = JSON.parse(json)
        data_key = Base64.strict_decode64(input_hash['data_key'])
        plaintext_key = @kms.decrypt(:ciphertext_blob => data_key).plaintext
        cipher = Gibberish::AES.new(plaintext_key)
        plaintext = cipher.decrypt(JSON.generate(input_hash['ciphertext']))
        plaintext
      end

      # Decrypts an env-formatted text string.
      # A file is considered to be env-formatted when:
      # - Each line consists of K=V pairs
      # - Each V is a JSON string that contains a Gibberish
      #   payload (ciphertext, IV, salt, etc) and an encrypted
      #   data key that was used to encrypt the ciphertext
      # @return [String]
      def decrypt_env_file(env_body)
        new_text = []
        env_body.each_line do |l|
          k, v = l.match(ENV_LINE_REGEX).captures
          dec_v = decrypt(v)
          new_text << "#{k}=#{dec_v}"
        end
        new_text
      end

    end
  end
end
