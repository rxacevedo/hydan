# Class to simplify KMS encryption interface

module SecretsHelper
  module KMS
    class EncryptionHelper

      ENV_LINE_REGEX = /(.*?)=(.*)/

      # Initializes the EncryptionHelper object with an
      # Aws::KMS::Client.
      def initialize
        @kms = Aws::KMS::Client.new(
          region: SecretsHelper::Const::AWS_REGION
        )
      end

      # Returns the KMS key ID for a given alias
      def get_kms_key_id(kms_key_alias)
        unless @kms.nil?
          aliases = @kms.list_aliases.aliases
          kms_key = aliases.find { |a| a.alias_name == kms_key_alias }
          kms_key_id = kms_key.target_key_id
          kms_key_id
        end
      end

      # Returns a JSON string containing the ciphertext (Base64 encoded)
      # and the encrypted data key used to encrypt it
      def encrypt(plaintext, kms_key_id, &block)
        unwrapped = block.call(plaintext) if block
        resp = @kms.generate_data_key(
          key_id: kms_key_id,
          key_spec: 'AES_256'
        )
        cipher = Gibberish::AES.new(resp[:plaintext])
        output = {
          'ciphertext' => JSON.parse(cipher.encrypt(unwrapped || plaintext)),
          'data_key' => Base64.strict_encode64(resp[:ciphertext_blob])
        }
        JSON.pretty_generate output
      end

      def encrypt_env_file(plaintext, kms_key_id)
        new_text = []
        plaintext.each_line do |l|
          k, v = l.match(ENV_LINE_REGEX).captures
          enc_v = JSON.generate(JSON.parse(encrypt(v, kms_key_id)))
          new_text << "#{k}=#{enc_v}"
        end
        new_text
      end

    end
  end
end
