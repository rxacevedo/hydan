require 'aws-sdk'
require 'base64'
require 'English'
require 'gibberish'
require 'secretshelper/kms/encrypt'
require 'secretshelper/kms/decrypt'
require 'secretshelper/const'
require 'secretshelper/s3'
require 'logger'
require 'thor'

module SecretsHelper
  class CLI < Thor

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

      client = SecretsHelper::KMS::EncryptionHelper.new
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

      client = SecretsHelper::KMS::DecryptionHelper.new

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
    subcommand 's3', SecretsHelper::S3

  end
end
