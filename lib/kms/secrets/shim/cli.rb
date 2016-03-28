require 'kms/secrets/shim'
require 'kms/secrets/shim/encrypt'
require 'kms/secrets/shim/decrypt'
require 'thor'
require 'English'
require 'logger'
require 'pp'


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
  LOGGER.level = Logger::INFO

  desc 'encrypt', 'Encrypts a string or file'
  method_option :file, :type => :string
  method_option :out, :type => :string
  method_option :key_alias, :type => :string, :require => true
  def encrypt(*args)
    text = args.join ' '
    LOGGER.debug "Args: #{text}"
    client = Kms::Secrets::Shim::EncryptionHelper.new
    if options[:file]
      file = File.open(options[:file], 'r')
      new_file = client.encrypt(file, options[:key_alias])
      LOGGER.info "Encrypted file saved at: #{new_file}"
    else
      # Encrypt plaintext
      ciphertext_base64 = client.encrypt(text, options[:key_alias])
      puts JSON.pretty_generate(ciphertext_base64)
    end
  end

  desc 'decrypt', 'Decrypts a string or file'
  method_option :file, :type => :string
  method_option :out, :type => :string
  def decrypt(*args)

    # Testing
    data = ''
    data << $LAST_READ_LINE while $stdin.gets
    # End testing

    client = Kms::Secrets::Shim::DecryptionHelper.new

    # case data
    # when NilClass
    # when String
    # else
    #   puts "No case..."
    # end

    plaintext = client.decrypt(data)
    puts "Decrypted: #{plaintext}"
  end

end
