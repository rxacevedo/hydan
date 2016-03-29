require "secretshelper/version"
require "secretshelper/cli"

module SecretsHelper
  unless ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
    # Holy NAME
    Aws.config.update(
      region: SecretsHelper::Const::AWS_REGION,
      credentials: Aws::SharedCredentials.new(
        profile_name: SecretsHelper::Const::AWS_PROFILE
      )
    )
  end
end
