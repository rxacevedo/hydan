require 'aws-sdk'
require 'base64'
require 'English'
require 'gibberish'
require 'logger'
require 'thor'
require 'secretshelper/kms/encrypt'
require 'secretshelper/kms/decrypt'
require 'secretshelper/path_types'
require 'secretshelper/crypto'
require 'secretshelper/crypto/encrypt'
require 'secretshelper/crypto/decrypt'
require 'secretshelper/s3'
require "secretshelper/cli"
require "secretshelper/version"

module SecretsHelper
  # TODO: Control when this runs, currently each time the module
  # is loaded, the below code runs
  unless ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
    Aws.config.update(
      credentials: Aws::SharedCredentials.new(
        profile_name: ENV['AWS_DEFAULT_PROFILE']
      )
    )
  end
end
