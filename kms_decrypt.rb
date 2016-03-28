class KMSDecryptionHelper

  def initialize
    @kms = Aws::KMS::Client.new(region: Const::AWS_REGION)
  end

  def decrypt(ciphertext)
    case ciphertext
    when File
      decrypt_file(ciphertext, data_key)
    when String
      input_hash = JSON.parse(ciphertext)
      data_key = Base64.strict_decode64(input_hash['data_key'])
      plaintext_key = @kms.decrypt(:ciphertext_blob => data_key).plaintext
      plaintext = decrypt_string(input_hash['ciphertext'], plaintext_key)
      plaintext
    end
  end

  # Takes a Base64 encoded string and decrypts it
  # using the associated data key
  def decrypt_string(string, data_key)
      cipher = Gibberish::AES.new(data_key)
      plaintext = cipher.decrypt(string)
      plaintext
  end

  # Takes a binary-encoded file and decrypts it 
  # using the associated data key
  def decrypt_file(file, data_key)
  end

end
