require "secretshelper/cli"
require "secretshelper/version"

module SecretsHelper
  # TODO: Control when this runs, currently each time the module
  # is loaded, the below code runs
  unless ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
    Aws.config.update(
      region: SecretsHelper::Const::AWS_REGION,
      credentials: Aws::SharedCredentials.new(
        profile_name: SecretsHelper::Const::AWS_PROFILE
      )
    )
  end
end
