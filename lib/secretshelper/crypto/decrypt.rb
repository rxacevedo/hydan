module SecretsHelper
  module Crypto
    class DecryptionHelper

      def initialize(symmetric_key)
        @symmetric_key = symmetric_key
        @generator = OpenSSL::Cipher.new(Crypto::DEFAULT_CIPHER)
      end

      # Decrypts a JSON object
      # @return [String]
      def decrypt(json)
        input_hash = JSON.parse(json)
        data_key = Base64.strict_decode64(input_hash['data_key'])
        key_cipher = Gibberish::AES.new(@symmetric_key)
        plaintext_key = key_cipher.decrypt(data_key)
        data_cipher = Gibberish::AES.new(plaintext_key)
        plaintext = data_cipher.decrypt(JSON.generate(input_hash['ciphertext']))
        plaintext
      end

      # # Decrypts an env-formatted text string.
      # # A file is considered to be env-formatted when:
      # # - Each line consists of K=V pairs
      # # - Each V is a JSON string that contains a Gibberish
      # #   payload (ciphertext, IV, salt, etc) and an encrypted
      # #   data key that was used to encrypt the ciphertext
      # # @return [String]
      # def decrypt_env_file(env_body)
      #   new_text = []
      #   env_body.each_line do |l|
      #     k, v = l.match(ENV_LINE_REGEX).captures
      #     dec_v = decrypt(v)
      #     new_text << "#{k}=#{dec_v}"
      #   end
      #   new_text
      # end
    end
  end
end
