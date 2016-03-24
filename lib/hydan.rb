require 'aws-sdk'
require 'base64'
require 'English'
require 'gibberish'
require 'logger'
require 'thor'
require 'hydan/crypto/kms'
require 'hydan/crypto/kms/encrypt'
require 'hydan/crypto/kms/decrypt'
require 'hydan/path_types'
require 'hydan/io'
require 'hydan/crypto'
require 'hydan/crypto/encrypt'
require 'hydan/crypto/decrypt'
require 'hydan/s3'
require 'hydan/cli'
require 'hydan/version'

module Hydan
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
