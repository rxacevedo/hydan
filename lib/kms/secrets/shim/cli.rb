require 'aws-sdk'
require 'base64'
require 'English'
require 'gibberish'
require 'kms/secrets/shim'
require 'kms/secrets/shim/encrypt'
require 'kms/secrets/shim/decrypt'
require 'kms/secrets/shim/const'
require 'logger'
require 'thor'


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
    kms_key_id = client.get_kms_key_id options[:key_alias]

    if options[:file]
      # Encrypt file, write to new file
      file = File.open(options[:file], 'r')
      output = client.encrypt_file(file, kms_key_id)
      File.open(options[:out], 'w') { |f| f.write output } if options[:out]
      # LOGGER.info "Encrypted file saved at: #{new_file}"
      puts output unless options[:out]
    else
      # Encrypt plaintext
      ciphertext_json = client.encrypt_string(text, kms_key_id)
      puts ciphertext_json
    end
  end

  desc 'decrypt', 'Decrypts a string or file'
  method_option :file, :type => :string
  method_option :out, :type => :string
  def decrypt(*args)

    client = Kms::Secrets::Shim::DecryptionHelper.new

    case options[:file]
    when NilClass # No file specified, read from STDIN
      data = ''
      data << $LAST_READ_LINE while $stdin.gets
      plaintext = client.decrypt(data)
      puts "Decrypted: #{plaintext}"
    when String # File path was passed in
      file = File.open(options[:file], 'r')
      plaintext = client.decrypt(file.read)
      puts plaintext unless options[:out]
      File.open(options[:out], 'w') { |f| f.write plaintext } if options[:out]
    else
      puts "No mechanism implemented for: #{options[:file]}"
    end

  end

end
