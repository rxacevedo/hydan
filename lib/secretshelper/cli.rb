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
    method_option :key, :type => :string, :required => true
    def decrypt(*args)


      key = Base64.strict_decode64(options[:key])
      client = SecretsHelper::Crypto::DecryptionHelper.new(key)

      if options[:file]
        file = File.open(options[:file], 'r')
        plaintext = client.decrypt(file.read) unless options[:env_formatted]
        plaintext = client.decrypt_env_file(file.read) if options[:env_formatted]
        handle_output(plaintext)
      else
        data = handle_stdin
        plaintext = client.decrypt(data) unless options[:env_formatted]
        plaintext = client.decrypt_env_file(data) if options[:env_formatted]
        handle_output(plaintext)
      end

    end

    desc 's3', 'Use the S3 API'
    subcommand 's3', SecretsHelper::S3::S3Cmd

    desc 'kms', 'Use the KMS API for encryption/decryption'
    subcommand 'kms', SecretsHelper::Crypto::KMS::KMSCmd

  end
end
