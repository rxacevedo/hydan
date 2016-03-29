require 'thor'

module SecretsHelper
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
end
