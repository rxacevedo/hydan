module SecretsHelper
  class CLI < Thor

    include SecretsHelper::Crypto
    LOGGER       = Logger.new(STDOUT)
    LOGGER.level = Logger::INFO

    desc 'encrypt', 'Encrypts a string or file'
    method_option :file, :type => :string
    method_option :env_formatted, :type => :boolean
    method_option :plaintext, :type => :array
    method_option :kms, :type => :boolean
    method_option :out, :type => :string
    method_option :key, :type => :string, :required => true
    def encrypt(*args)
      key = Base64.strict_decode64(options[:key])
      client = SecretsHelper::Crypto::EncryptionHelper.new(key)


      if options[:file]
        file = File.open(options[:file], 'r')
        json = client.encrypt(file) { |f, k| f.read } unless options[:env_formatted]
        json = client.encrypt_env_file(file) { |f, k| f.read } if options[:env_formatted]
        handle_output(json)
      else
        text = handle_stdin
        json = client.encrypt(text) unless options[:env_formatted]
        json = client.encrypt_env_file(text) if options[:env_formatted]
        handle_output(json)
      end
    end


    desc 'decrypt', 'Decrypts a string or file'
    method_option :file, :type => :string
    method_option :env_formatted, :type => :boolean
    method_option :out, :type => :string
    def decrypt(*args)

      # # PHASES:
      # # - Initialize client
      # # - HANDLE INPUT
      # # - ENCRYPT
      # # - HANDLE OUTPUT

      # client = SecretsHelper::KMS::DecryptionHelper.new

      # if options[:file]
      #   # Decrypt file that was encrypted
      #   # by client
      #   file = File.open(options[:file], 'r')

      #   # TODO: This kind of control-flow feels weird.
      #   plaintext = client.decrypt(file.read) unless options[:env_formatted]
      #   plaintext = client.decrypt_env_file(file.read) if options[:env_formatted]

      #   # Output in both cases
      #   puts plaintext unless options[:out]
      #   File.open(options[:out], 'w') { |f| f.write plaintext } if options[:out]
      # else
      #   data = ''
      #   data << $LAST_READ_LINE while $stdin.gets
      #   plaintext = client.decrypt(data) unless options[:env_formatted]
      #   plaintext = client.decrypt_env_file(data) if options[:env_formatted]

      #   # STDOUT is assumed for STDIN input (no CLI
      #   # --text input currently implemented)
      #   # TODO: Don't assume STDOUT, check for --out flag
      #   puts plaintext
    end

    desc 's3', 'Use the S3 API'
    subcommand 's3', SecretsHelper::S3::S3Cmd

    desc 'kms', 'Use the KMS API for encryption/decryption'
    subcommand 'kms', SecretsHelper::Crypto::KMS::KMSCmd

  end
end
