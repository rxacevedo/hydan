require 'aws-sdk'

# TODO: Factor out, this shadows superclass' instance
AWS_REGION = 'us-east-1'.freeze

# Class to simplify KMS encryption interface
class KMSEncryptionHelper

  def initialize
    @kms = Aws::KMS::Client.new(region: AWS_REGION)
  end

  # Returns a base64 encoded string that represents the encrypted content
  def encrypt(body, kms_key_alias)
    kms_key_id = get_kms_key_id(kms_key_alias)
    puts "Body: #{body}, alias: #{kms_key_alias}, id: #{kms_key_id}"

    # Inspect object type and dispatch
    case body
    when File
      encrypt_file(body, kms_key_id)
    when String
      encrypt_string(body, kms_key_id)
    else
      puts "Error: no mechanism implemented for: #{body.class}"
      exit 1
    end
  end

  # Returns a File object pointing to the encrypted file
  def encrypt_file(file, kms_key_id)
  end

  def encrypt_string(string, kms_key_id)
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
