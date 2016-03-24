#!/usr/bin/env ruby

# Default credentials are loaded automatically from the following locations:
#
# - ENV['AWS_ACCESS_KEY_ID'] and ENV['AWS_SECRET_ACCESS_KEY']
# - Aws.config[:credentials]
# - The shared credentials ini file at ~/.aws/credentials (more information)
# - From an instance profile when running on EC2

require 'aws-sdk'
require 'English'
require 'logger'
require 'optparse'
require 'pp'

# Debug
# require 'pry'

require './aws_const.rb'
require './kms_encrypt.rb'
require './kms_decrypt.rb'

LOGGER                = Logger.new(STDOUT)
LOGGER.level          = Logger::INFO

# This class encrypts/uploads and downloads/decrypts files
# given a specified path and CMK alias
# class EncryptedS3EnvClient
#   # TODO: The @kms instance var is also utilized in KMSDecryptionHelper,
#   # if since there is no possiblity for concurrent usage of this
#   # particular resource (since this is a CLI app and invocations will
#   # spawn a new Ruby process), it might be a good idea to open up scope
#   # and perhaps put this object into a module so that the instantiation
#   # logic isn't duplicated in more than one place.
#   attr_accessor :s3, :kms
#
#   # Set up AWS credentials
#   def initialize(key_alias)
#     kms_init!
#     s3_init!(key_alias, @kms)
#   end
#
#   # Initializes the KMS client
#   def kms_init!
#     @kms = Aws::KMS::Client.new(region: Const::AWS_REGION)
#   end
#
#   # Returns the CMK ID for the given alias
#   def kms_get_key(key_alias)
#     aliases = @kms.list_aliases.aliases
#     key = aliases.find { |alias_struct| alias_struct.alias_name == key_alias }
#     key_id = key.target_key_id
#     LOGGER.debug "Key alias: #{key_alias}, key id: #{key_id}"
#     key_id
#   end
#
#   # Initializes the S3 client and the encrypted wrapper
#   def s3_init!(kms_alias, kms_client)
#     kms_key_id = kms_get_key(kms_alias)
#     @s3 = Aws::S3::Client.new(region: Const::AWS_REGION)
#     @s3_enc = Aws::S3::Encryption::Client.new(
#       client: @s3,
#       kms_key_id: kms_key_id,
#       kms_client: kms_client
#     )
#   end
# end
#
# Uploader
# class EncryptedS3EnvUploader < EncryptedS3EnvClient
#   # Uploads the file using the encrypted uploader
#   # (currently without SSE)
#   def upload!(body, bucket, key)
#     @s3_enc.put_object(
#       bucket: bucket,
#       key:  key,
#       body: body
#     )
#   end
# end
#
# # Downloader
# class EncryptedS3EnvDownloader < EncryptedS3EnvClient
#   def download!(bucket, key)
#     response = @s3_enc.get_object(bucket: bucket, key: key)
#     response.body.string
#   end
# end

unless ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
  Aws.config.update(
    region: Const::AWS_REGION,
    # TODO: Don't hard-code this
    credentials: Aws::SharedCredentials.new(profile_name: Const::AWS_PROFILE)
  )
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
  opts.on('-e', '--envelope', 'Use envelope encryption, or expect an encrypted data key for decryption') do |e|
    options[:envelope] = p
  end
  opts.on('-h', '--help') do
    puts opts
    exit
  end
end.parse!

action = ARGV.find { |arg| Const::VALID_ACTIONS.include? arg }

LOGGER.debug "Action: #{action}, class: #{action.class}"

case action
when 'encrypt'
  client = KMSEncryptionHelper.new
  ciphertext_base64 = client.encrypt(options[:plaintext], options[:alias])
  puts JSON.pretty_generate(ciphertext_base64)
when 'decrypt'
  # Testing
  data = ''
  data << $LAST_READ_LINE while $stdin.gets
  # End testing

  client = KMSDecryptionHelper.new
  plaintext = client.decrypt(data)
  puts "Decrypted: #{plaintext}"

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
