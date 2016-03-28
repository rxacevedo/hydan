# Class to simplify KMS encryption interface
class Kms::Secrets::Shim::EncryptionHelper

  def initialize
    @kms = Aws::KMS::Client.new(
      region: Kms::Secrets::Shim::Const::AWS_REGION
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

  # TODO: These two methods are basically the same

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
      'ciphertext' => cipher.encrypt(unwrapped || plaintext),
      'data_key' => Base64.strict_encode64(resp[:ciphertext_blob])
    }
    JSON.pretty_generate output
  end

end
