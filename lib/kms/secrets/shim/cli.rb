require 'kms/secrets/shim'
require 'kms/secrets/shim/encrypt'
require 'thor'
require 'logger'


unless ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
  # Holy NAME
  Aws.config.update(
    region: Kms::Secrets::Shim::Const::AWS_REGION,
    credentials: Aws::SharedCredentials.new(
      profile_name: Kms::Secrets::Shim::Const::AWS_PROFILE
    )
  )
end

class Kms::Secrets::Shim::CLI < Thor

  LOGGER = Logger.new(STDOUT)
  LOGGER.level = Logger::DEBUG

  method_option :file, :type => :string
  method_option :key_alias, :type => :string, :require => true
  desc "encrypt", "Encrypts a string or file"
  def encrypt(*args)
    text = args.join ' '
    LOGGER.debug "Args: #{text}"

    if options[:file]
    else 
      # Encrypt plaintext
      client = Kms::Secrets::Shim::EncryptionHelper.new
      ciphertext_base64 = client.encrypt(text, options[:key_alias])
      puts JSON.pretty_generate(ciphertext_base64)
    end

  end

end
