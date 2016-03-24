#!/usr/bin/env ruby

# Default credentials are loaded automatically from the following locations:
#
# - ENV['AWS_ACCESS_KEY_ID'] and ENV['AWS_SECRET_ACCESS_KEY']
# - Aws.config[:credentials]
# - The shared credentials ini file at ~/.aws/credentials (more information)
# - From an instance profile when running on EC2

require 'aws-sdk'
require 'logger'
require 'optparse'
require 'pp'

# Debug
require 'pry'

require './kms_encrypt.rb'

LOGGER                = Logger.new(STDOUT)
LOGGER.level          = Logger::DEBUG

# Defaults
AWS_REGION            = 'us-east-1'.freeze
AWS_PROFILE           = 'terraform-qa'.freeze
AWS_ACCESS_KEY_ID     = ''.freeze
AWS_SECRET_ACCESS_KEY = ''.freeze

VALID_ACTIONS = ['encrypt','decrypt','upload','download'].freeze
OUT_BEGIN = '-----BEGIN S3 OBJECT OUTPUT-----'.freeze
OUT_END  =  '-----END S3 OBJECT OUTPUT-----'.freeze

# This class encrypts/uploads and downloads/decrypts files
# given a specified path and CMK alias
class EncryptedS3EnvClient
  attr_accessor :s3, :kms

  # Set up AWS credentials
  def initialize(key_alias)
    unless ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
      Aws.config.update(
        region: AWS_REGION,
        # TODO: Don't hard-code this
        credentials: Aws::SharedCredentials.new(profile_name: AWS_PROFILE)
      )
    end
    kms_init!
    s3_init!(key_alias, @kms)
  end

  # Initializes the KMS client
  def kms_init!
    @kms = Aws::KMS::Client.new(region: AWS_REGION)
  end

  # Returns the CMK ID for the given alias
  def kms_get_key(key_alias)
    aliases = @kms.list_aliases.aliases
    key = aliases.find { |alias_struct| alias_struct.alias_name == key_alias }
    key_id = key.target_key_id
    LOGGER.debug "Key alias: #{key_alias}, key id: #{key_id}"
    key_id
  end

  # Initializes the S3 client and the encrypted wrapper
  def s3_init!(kms_alias, kms_client)
    kms_key_id = kms_get_key(kms_alias)
    @s3 = Aws::S3::Client.new(region: AWS_REGION)
    @s3_enc = Aws::S3::Encryption::Client.new(
      client: @s3,
      kms_key_id: kms_key_id,
      kms_client: kms_client
    )
  end
end

# Uploader
class EncryptedS3EnvUploader < EncryptedS3EnvClient
  # Uploads the file using the encrypted uploader
  # (currently without SSE)
  def upload!(body, bucket, key)
    @s3_enc.put_object(
      bucket: bucket,
      key:  key,
      body: body
    )
  end
end

# Downloader
class EncryptedS3EnvDownloader < EncryptedS3EnvClient
  def download!(bucket, key)
    response = @s3_enc.get_object(bucket: bucket, key: key)
    response.body.string
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: encrypt.rb [options]'
  opts.on('-v', '--[no-]verbose', 'Run verbosely') do |v|
    options[:verbose] = v
  end
  opts.on('-a ALIAS', '--alias ALIAS', 'The KMS key alias') do |k|
    options[:alias] = k
  end
  opts.on('-f FILE', '--file FILE', 'The file to upload') do |f|
    options[:file] = f
  end
  opts.on('-b BUCKET', '--bucket BUCKET', 'The S3 bucket') do |b|
    options[:bucket] = b
  end
  opts.on('-k KEY', '--key KEY', 'The key/prefix in the S3 bucket') do |k|
    options[:key] = k
  end
  opts.on('--plaintext TEXT', 'Plaintext to be encrypted') do |p|
    options[:plaintext] = p
  end
  opts.on('-h', '--help') do
    puts opts
    exit
  end
end.parse!

action = ARGV.find { |arg| VALID_ACTIONS.include? arg }

LOGGER.debug "Action: #{action}, class: #{action.class}"

case action
when 'encrypt'
  client = KMSEncryptionHelper.new
  ciphertext = client.encrypt(options[:plaintext], options[:alias])
  puts ciphertext
when 'decrypt'
  puts 'DISABLED'
when 'upload'
  puts 'DISABLED'
  # client = EncryptedS3EnvUploader.new(options[:alias])
  # client.upload!(
  #   File.open(options[:file], 'r').read,
  #   options[:bucket],
  #   options[:key]
  # )
when 'download'
  puts 'DISABLED'
  # client = EncryptedS3EnvDownloader.new(options[:alias])
  # data = client.download!(options[:bucket], options[:key])
  # puts OUT_BEGIN
  # puts data
  # puts OUT_END
else
  LOGGER.error "Error: No action implemented for action: #{action}"
end
