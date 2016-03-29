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

class S3 < Thor
  # - If cp is copying *from S3 to local*, then --decrypt can mean "decrypt the file before writing to disk"
  # - If cp is copying *from local to s3*, then --encrypt can mean "encrypt the file before writing to S3"
  # TODO: This still doesn't account for the S3EncryptedClient's upload/download functions, which read/write binary 
  # encoded files (not the JSON/base64 stuff that I'm doing here).
  # Options:
  # - cp <SRC> <DEST> (parse paths to determine if S3 bucket/key prefix vs local directory
  desc 'cp', 'Use the S3 API to copy files'
  method_option :encrypt, :type => :boolean
  method_option :decrypt, :type => :boolean
  def cp (*args)
  end

  no_commands do
    def parse_paths(*paths)
    end
  end

end

class Kms::Secrets::Shim::CLI < Thor

  LOGGER =       Logger.new(STDOUT)
  LOGGER.level = Logger::INFO

  desc 'encrypt', 'Encrypts a string or file'
  method_option :file, :type => :string
  method_option :plaintext, :type => :string
  method_option :out, :type => :string
  method_option :key_alias, :type => :string, :require => true
  def encrypt(*args)

    # PHASES:
    # - Initialize client
    # - HANDLE INPUT
    # - ENCRYPT
    # - HANDLE OUTPUT

    client = Kms::Secrets::Shim::EncryptionHelper.new
    kms_key_id = client.get_kms_key_id options[:key_alias]

    # CLI args other than flags are *ignored* with file input
    if options[:file]
      # Encrypt file, write to new file
      file = File.open(options[:file], 'r')
      # We "unwrap" the text with an optional block that #encrypt
      # applies to the input if supplied
      json = client.encrypt(file, kms_key_id) { |f, k| f.read }

      # TODO: Don't duplicate this, file output is supported in either case
      File.open(options[:out], 'w') { |f| f.write json } if options[:out]
      puts json unless options[:out]
    else
      # Handle STDIN/CLI text (STDIN ignored if CLI present)
      text = options[:plaintext] if options[:plaintext]
      unless options[:plaintext]
        text = ''
        text << $LAST_READ_LINE while $stdin.gets
      end
      # No block specified here, encrypt assumes the input text is
      # plaintext unless a block is passed in to applyt to the value
      json = client.encrypt(text, kms_key_id)

      # TODO: Don't duplicate this, file output is supported in either case
      File.open(options[:out], 'w') { |f| f.write json } if options[:out]
      puts json unless options[:out]
    end
  end

  desc 'decrypt', 'Decrypts a string or file'
  method_option :file, :type => :string
  method_option :out, :type => :string
  def decrypt(*args)

    # PHASES:
    # - Initialize client
    # - HANDLE INPUT
    # - ENCRYPT
    # - HANDLE OUTPUT

    client = Kms::Secrets::Shim::DecryptionHelper.new

    if options[:file]
      # Decrypt file that was encrypted
      # by client
      file = File.open(options[:file], 'r')
      plaintext = client.decrypt(file.read)

      # Output in both cases
      puts plaintext unless options[:out]
      File.open(options[:out], 'w') { |f| f.write plaintext } if options[:out]
    else
      data = ''
      data << $LAST_READ_LINE while $stdin.gets
      plaintext = client.decrypt(data)

      # STDOUT is assumed for STDIN input (no CLI
      # --text input currently implemented)
      # TODO: Don't assume STDOUT, check for --out flag
      puts plaintext
    end

  end

  desc 's3', 'Use the S3 API'
  subcommand 's3', S3

end
