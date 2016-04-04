module SecretsHelper
  class CLI < Thor

    include SecretsHelper::Crypto
    LOGGER       = Logger.new(STDOUT)
    LOGGER.level = Logger::INFO

    desc 'encrypt', 'Encrypts a string or file'
    method_option :file, :type => :string # Only used for branching to encrypt_file
    method_option :env_formatted, :type => :boolean
    method_option :plaintext, :type => :array
    method_option :out_file, :type => :string
    method_option :key_out, :type => :string
    method_option :master_key, :type => :string, :required => true
    def encrypt(*args)
      if options[:file]
        invoke :encrypt_file
      else
        master_key = Base64.strict_decode64(options[:master_key])
        client = SecretsHelper::Crypto::EncryptionHelper.new(master_key)
        text = handle_stdin
        json = client.encrypt(text) unless options[:env_formatted]
        json = client.encrypt_env_formatted(text) if options[:env_formatted]
        handle_output(json)
      end
    end

    desc 'encrypt-file', 'Decrypt a file'
    method_option :file, :type => :string, :required => true
    method_option :out_file, :type => :string, :required => true
    method_option :key_out, :type => :string
    method_option :master_key, :type => :string, :required => true
    def encrypt_file(*args)
      puts "WE OUT THERE"
      master_key = Base64.strict_decode64(options[:master_key])
      client = SecretsHelper::Crypto::EncryptionHelper.new(master_key)
      encrypted_data_key_blob = client.encrypt_file(
        options[:file],
        options[:out_file]
      )
      handle_key_output(encrypted_data_key_blob, options[:key_out])
    end


    desc 'decrypt', 'Decrypts a string or file'
    method_option :file, :type => :string
    method_option :env_formatted, :type => :boolean
    method_option :out, :type => :string
    method_option :key, :type => :string, :required => true
    def decrypt(*args)
      if options[:file]
        invoke :decrypt_file
      else
        key = Base64.strict_decode64(options[:key])
        client = SecretsHelper::Crypto::DecryptionHelper.new(key)
        data = handle_stdin
        plaintext = client.decrypt(data) unless options[:env_formatted]
        plaintext = client.decrypt_env_file(data) if options[:env_formatted]
        handle_output(plaintext)
      end
    end

    desc 'decrypt-file', 'Decrypts a file'
    def decrypt_file(*args)
      file = File.open(options[:file], 'r')
      plaintext = client.decrypt(file.read) unless options[:env_formatted]
      plaintext = client.decrypt_env_file(file.read) if options[:env_formatted]
      handle_output(plaintext)
    end

    desc 's3', 'Use the S3 API'
    subcommand 's3', SecretsHelper::S3::S3Cmd

    desc 'kms', 'Use the KMS API for encryption/decryption'
    subcommand 'kms', SecretsHelper::Crypto::KMS::KMSCmd

  end
end
