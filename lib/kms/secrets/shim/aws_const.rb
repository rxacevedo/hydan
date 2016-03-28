module Kms
  module Secrets
    module Shim
      module Const
        # AWS
        AWS_REGION            = 'us-east-1'.freeze
        AWS_PROFILE           = 'terraform-qa'.freeze
        AWS_ACCESS_KEY_ID     = ''.freeze
        AWS_SECRET_ACCESS_KEY = ''.freeze
        # Rest
        VALID_ACTIONS = ['encrypt','decrypt','upload','download'].freeze
        OUT_BEGIN = '-----BEGIN S3 OBJECT OUTPUT-----'.freeze
        OUT_END  =  '-----END S3 OBJECT OUTPUT-----'.freeze
      end
    end
  end
end
