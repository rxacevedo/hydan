module SecretsHelper
  module KMS
    class KMSCmd < Thor

      no_tasks do

        # Reads text from STDIN, or uses the value supplied with
        # --plaintext, if any. Returns the text.
        # @return [String]
        def handle_stdin
          text = options[:plaintext].join ' ' if options[:plaintext]
          unless options[:plaintext]
            text = ''
            text << $LAST_READ_LINE while $stdin.gets
          end
          text
        end

        # Output phase of the encryption process, prints output
        # to STDOUT or uses the value supplied with --out to write
        # output to a file, if any.
        # @return [Nil]
        def handle_output(json)
          File.open(options[:out], 'w') { |f| f.write json } if options[:out]
          puts json unless options[:out]
          nil
        end
      end

      desc 'encrypt', 'Encrypts a file or string'
      method_option :file, :type => :string
      method_option :env_formatted, :type => :boolean
      method_option :plaintext, :type => :array
      method_option :kms, :type => :boolean
      method_option :out, :type => :string
      method_option :key_alias, :type => :string, :required => true
      def encrypt(*args)

        client = SecretsHelper::KMS::EncryptionHelper.new
        kms_key_id = client.get_kms_key_id options[:key_alias]

        if options[:file]
          file = File.open(options[:file], 'r')
          json = client.encrypt(file, kms_key_id) { |f, k| f.read } unless options[:env_formatted]
          json = client.encrypt_env_file(file, kms_key_id) { |f, k| f.read } if options[:env_formatted]
          handle_output(json)
        else
          text = handle_stdin
          json = client.encrypt(text, kms_key_id)
          handle_output(json)
        end
      end

      desc 'decrypt', 'Decrypts a string or file'
      method_option :file, :type => :string
      method_option :env_formatted, :type => :boolean
      method_option :out, :type => :string
      def decrypt(*args)

        client = SecretsHelper::KMS::DecryptionHelper.new

        if options[:file]
          file = File.open(options[:file], 'r')
          plaintext = client.decrypt(file.read) unless options[:env_formatted]
          plaintext = client.decrypt_env_file(file.read) if options[:env_formatted]
          handle_output(plaintext)
        else
          # TODO: This might allow ciphertext to be supplied via --plaintext, which is wrong
          data = handle_stdin
          plaintext = client.decrypt(data) unless options[:env_formatted]
          plaintext = client.decrypt_env_file(data) if options[:env_formatted]
          handle_output(plaintext)
        end
      end
    end
  end
end
