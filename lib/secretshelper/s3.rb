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

    # no_commands do
    #   def parse_paths(*paths)
    #   end
    # end

  end

  # Enumerate types
  module PathTypes
    S3 = :s3
    # S3_Folder = :s3_folder
    # S3_Object = :s3_object
    UNIX = :unix
  end

  # S3 wrapper class
  class S3Helper
    def initialize(kms_key_id = nil)
      @s3 = Aws::S3::Client.new(region: SecretsHelper::Const::AWS_REGION) unless kms_key_id
      @s3 = Aws::S3::Encryption::Client.new(
        kms_key_id: kms_key_id
      ) if kms_key_id
    end

    # Performs a PutObject operation for content at s3://bucket/key
    def upload!(bucket, key, body)
      @s3.put_object(
        bucket: bucket,
        key:  key,
        body: body
      )
    end

    # Downloads the object located at s3://bucket/prefix and writes
    # the content to dest
    def download(bucket, prefix, dest = nil)
      resp = @s3.get_object(bucket: bucket, key: prefix)
      content = resp.body.string
      File.open(dest, 'w') { |f| f.write content } if dest
      puts content unless dest
    end

    # TODO: It would probably be a good idea to move this logic
    # into a module since it has no need for the S3 client itself.
    # Maybe a good candidate for a mixin
    # Determines whether a path is a filesystem or S3 path. 
    def parse_path(path)
      # If we "parse" it as an S3 path, we'll let the S3 client throw
      # an error if it's a non-existant path
      if path.start_with? 's3://' then PathTypes::S3
      elsif File.exists? path then PathTypes::UNIX
      else raise "Invalid path: #{path}"
      end
    end
  end

end
