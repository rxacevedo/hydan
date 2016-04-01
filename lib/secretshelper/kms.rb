module SecretsHelper
  module KMS
    class KMSCmd

      desc 'encrypt', 'Encrypt text or a file'
      method_option :key_alias, :type => :string
      def encrypt(*args)
      end

      def decrypt(*args)
      end

    end
  end
end
