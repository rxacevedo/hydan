module SecretsHelper
  class CLIBase < Thor
    def self.shared_options
      method_option(
        :master_key,
        :type => :string,
        :desc => 'The symmetric master key used to encrypt the exported data key',
        :required => true
      )
    end
    def self.shared_text_options
      method_option(
        :env_formatted,
        :type => :boolean,
        :desc => 'Indicates that the input is .env formatted (K=V). Results in K=encrypt(V) output.'
      )
      method_option(
        :text,
        :type => :array,
        :desc => 'The plaintext to be encrypted'
      )
    end
    def self.shared_file_options
      method_option(
        :in,
        :type => :string,
        :desc => 'The file being encrypted'
      )
      method_option(
        :out,
        :type => :string,
        :desc => 'Where the encrypted content should be written'
      )
    end
  end

  class CLI < CLIBase

    include SecretsHelper::Crypto
    LOGGER       = Logger.new(STDOUT)
    LOGGER.level = Logger::INFO

    desc 'encrypt', 'Encrypt a string or file'
    shared_options
    shared_text_options
    # This is only here to support branching over to encrypt-file
    method_option(
      :in,
      :type => :string,
      :desc => 'The file being encrypted'
    )
    def encrypt(*args)
      if options[:in]
        invoke :encrypt_file
      else
        master_key = Base64.strict_decode64(options[:master_key])
        client = SecretsHelper::Crypto::EncryptionHelper.new(master_key)
        data = handle_input(options)
        json = client.encrypt(data) unless options[:env_formatted]
        json = client.encrypt_env_formatted(data) if options[:env_formatted]
        handle_output(json)
      end
    end

    desc 'encrypt-file', 'Encrypt a file'
    shared_options
    shared_file_options
    # Only used for file encryption
    method_option(
      :key_out,
      :type => :string,
      :desc => 'Where the encrypted data key should be written'
    )
    def encrypt_file(*args)
      master_key = Base64.strict_decode64(options[:master_key])
      client = SecretsHelper::Crypto::EncryptionHelper.new(master_key)
      encrypted_data_key_blob = client.encrypt_file(
        options[:in],
        options[:out]
      )
      handle_key_output(encrypted_data_key_blob, options[:key_out])
    end

    desc 'decrypt', 'Decrypt a string or file'
    shared_options
    shared_text_options
    # This is only here to support branching over to encrypt-file
    method_option(
      :in,
      :type => :string,
      :desc => 'The file being encrypted'
    )
    def decrypt(*args)
      if options[:in]
        invoke :decrypt_file
      else
        key = Base64.strict_decode64(options[:master_key])
        client = SecretsHelper::Crypto::DecryptionHelper.new(key)
        data = handle_input(options)
        plaintext = client.decrypt(data) unless options[:env_formatted]
        plaintext = client.decrypt_env_file(data) if options[:env_formatted]
        handle_output(plaintext)
      end
    end

    desc 'decrypt-file', 'Decrypt a file'
    shared_options
    shared_file_options
    method_option(
      :key,
      :type => :string,
      :desc => 'The data key used to decrypt encypted data',
      :required => true
    )
    def decrypt_file(*args)
      master_key = Base64.strict_decode64(options[:master_key])
      data_key = Base64.strict_decode64(options[:key])
      # TODO: Clear keys
      client = SecretsHelper::Crypto::DecryptionHelper.new(master_key)
      client.decrypt_file(options[:in], options[:out], data_key)
    end

    desc 's3', 'Use the S3 API'
    subcommand 's3', SecretsHelper::S3::S3Cmd

    desc 'kms', 'Use the KMS API for encryption/decryption'
    subcommand 'kms', SecretsHelper::Crypto::KMS::KMSCmd

  end
end
