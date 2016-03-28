require 'aws-sdk'
require 'base64'
require 'gibberish'
require 'kms/secrets/shim/aws_const'

# Class to simplify KMS encryption interface
class Kms::Secrets::Shim::EncryptionHelper

  def initialize
    @kms = Aws::KMS::Client.new(region: Kms::Secrets::Shim::Const::AWS_REGION)
  end

  # Returns a base64 encoded string that represents the encrypted content
  def encrypt(body, kms_key_alias)
    kms_key_id = get_kms_key_id(kms_key_alias)
    # puts "Body: #{body}, alias: #{kms_key_alias}, id: #{kms_key_id}"

    # Inspect object type and dispatch
    case body
    when File
      encrypt_file(body, '/tmp/new_file', kms_key_id)
    when String
      encrypt_string(body, kms_key_id)
    else
      puts "Error: no mechanism implemented for: #{body.class}"
      exit 1
    end
  end

  # Returns a File object pointing to the encrypted file
  def encrypt_file(file, dest, kms_key_id)
    body = File.open(file, 'r').read
    resp = @kms.encrypt(key_id: kms_key_id, plaintext: body)
    File.open(dest, 'w') do |f|
      f.write resp.ciphertext_blob
    end
    dest
  end

  # Returns a Base64 encoded version of the ciphertext
  def encrypt_string(string, kms_key_id)
    # resp = @kms.encrypt(key_id: kms_key_id, plaintext: string)
    resp = @kms.generate_data_key(
      key_id: kms_key_id,
      key_spec: 'AES_256'
    )
    cipher = Gibberish::AES.new(resp[:plaintext])
    output = {'ciphertext' => cipher.encrypt(string),
              'data_key' => Base64.strict_encode64(resp[:ciphertext_blob])}
    output
  end

  # Returns the KMS key ID for a given alias
  def get_kms_key_id(kms_key_alias)
    unless @kms.nil?
      aliases = @kms.list_aliases.aliases
      kms_key = aliases.find { |alias_struct| alias_struct.alias_name == kms_key_alias }
      kms_key_id = kms_key.target_key_id
      kms_key_id
    end
  end

  private :encrypt_file, :encrypt_string

end
