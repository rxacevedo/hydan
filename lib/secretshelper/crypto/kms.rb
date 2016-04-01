module SecretsHelper
  module Crypto
    module KMS
      class KMSCmd < Thor

        include SecretsHelper::Crypto
        # TODO: --plaintext would be better represented by --data
        desc 'encrypt', 'Encrypt a string or file'
        method_option :env_formatted, :type => :boolean
        method_option :file, :type => :string
        method_option :key_alias, :type => :string, :required => true
        method_option :out, :type => :string
        method_option :plaintext, :type => :array
        def encrypt(*args)

          client = SecretsHelper::Crypto::KMS::EncryptionHelper.new
          kms_key_id = client.get_kms_key_id options[:key_alias]

          if options[:file]
            file = File.open(options[:file], 'r')
            json = client.encrypt(file, kms_key_id) { |f, k| f.read } unless options[:env_formatted]
            json = client.encrypt_env_file(file, kms_key_id) { |f, k| f.read } if options[:env_formatted]
            handle_output(json)
          else
            text = handle_stdin
            json = client.encrypt(text, kms_key_id) unless options[:env_formatted]
            json = client.encrypt_env_file(text, kms_key_id) if options[:env_formatted]
            handle_output(json)
          end
        end

        desc 'decrypt', 'Decrypts a string or file'
        method_option :file, :type => :string
        method_option :env_formatted, :type => :boolean
        method_option :out, :type => :string
        def decrypt(*args)

          client = SecretsHelper::Crypto::KMS::DecryptionHelper.new

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
      end
    end
  end
end
