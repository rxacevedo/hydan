require 'thor'

module SecretsHelper
  # S3 command class
  class S3 < Thor
    # TODO: This still doesn't account for the S3EncryptedClient's upload/download functions, which read/write binary
    # encoded files (not the JSON/base64 stuff that I'm doing here).
    desc 'cp', 'Use the S3 API to copy files'
    method_option :encrypt, :type => :boolean
    method_option :decrypt, :type => :boolean
    # Copies src to dest (args[0] and args[1]). Handles S3->local (download)
    # and local->S3 (upload).
    def cp (*args)
      src, dest =  args.take 2
      src_type, dest_type = [S3Helper.parse_path(src), S3Helper.parse_path(dest)]

      event = if src_type == PathTypes::UNIX && dest_type == PathTypes::S3
                :upload
              elsif src_type == PathTypes::S3 && dest_type == PathTypes::UNIX
                :download
              else
                :invalid
              end

      if event == :upload
        bucket, key = S3Helper.parse_s3_path dest
        client = S3Helper.new(options[:encrypt])
        client.upload(bucket, key, File.open(src, 'r').read)
      elsif event == :download
        bucket, key = S3Helper.parse_s3_path src
        client = S3Helper.new(options[:decrypt])
        client.download(bucket, key, dest)
      else puts "Invalid"
      end

    end

  end

  # Enumerate types
  module PathTypes
    S3 = :s3
    # S3_Folder = :s3_folder
    # S3_Object = :s3_object
    UNIX = :unix
  end

  # Wrapper class surrounding common S3 functions
  class S3Helper
    S3_PATH_REGEX = /s3:\/\/(.*?)\/(.*)/

    # Initialize the S3Helper object. When a kms_key_id is given, the
    # client uses an Aws::S3::Encrpytion::Client. If omitted, a regular
    # Aws::S3::Client is used instead.
    def initialize(kms_key_id = nil)
      @s3 = Aws::S3::Client.new(region: SecretsHelper::Const::AWS_REGION) unless kms_key_id
      @s3 = Aws::S3::Encryption::Client.new(
        kms_key_id: kms_key_id
      ) if kms_key_id
    end

    # Performs a PutObject operation for content at s3://bucket/key
    def upload(bucket, key, body)
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

    # Parses a given string path and returns the type
    # (constants in SecretsHelper::PathTypes)
    def self.parse_path(path)
      # If we "parse" it as an S3 path, we'll let the S3 client throw
      # an error if it's a non-existant path
      return PathTypes::S3 if path.start_with? 's3://'
      return PathTypes::UNIX unless path.start_with? 's3://'
    end

    # Parses an S3 path and returns regex capture
    # groups [bucket, key]
    def self.parse_s3_path(s3_path)
      s3_path.match(S3_PATH_REGEX).captures
    end
  end

end
