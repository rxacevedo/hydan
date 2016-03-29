# Class to simplify KMS decryption interface
class Kms::Secrets::Shim::DecryptionHelper

  def initialize
    @kms = Aws::KMS::Client.new(
      region: Kms::Secrets::Shim::Const::AWS_REGION
    )
  end

  def decrypt(json)
    input_hash = JSON.parse(json)
    data_key = Base64.strict_decode64(input_hash['data_key'])
    plaintext_key = @kms.decrypt(:ciphertext_blob => data_key).plaintext
    cipher = Gibberish::AES.new(plaintext_key)
    plaintext = cipher.decrypt(input_hash['ciphertext'])
    plaintext
  end

end
