require 'test_helper'

class SecretsHelperTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::SecretsHelper::VERSION
  end

  # def test_that_encryption_via_stdin_works
  # end

  # def test_that_encryption_via_plaintext_flag_works
  # end

  # def test_that_decryption_via_stdin_works
  # end

  # def test_that_decryption_via_file_flag_works
  # end

  def test_that_path_parsing_s3_works
    client = SecretsHelper::S3Helper.new
    res = client.parse_path('s3://bogus/a/b/c/object') == SecretsHelper::PathTypes::S3
    assert res
  end

  def test_that_path_parsing_unix_works
    client = SecretsHelper::S3Helper.new
    res = client.parse_path('/usr') == SecretsHelper::PathTypes::UNIX
    assert res
  end
end
