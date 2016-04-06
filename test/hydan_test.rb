require 'test_helper'

class HydanTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Hydan::VERSION
  end

  ## AWS integration tests (these tests reqiure Internet access/valid AWS credentials)

  def test_that_kms_encryption_via_stdin_works
    plaintext = 'This is the plaintext'
    key_alias = 'alias/sbi/app-secrets'
    `echo #{plaintext} | bundle exec bin/hydan kms encrypt --key-alias #{key_alias}`
    assert true
  end

  def test_that_kms_encryption_via_plaintext_flag_works
    plaintext = 'CLI plaintext 1234567890 --==!@#$%^&*()_+'
    key_alias = 'alias/sbi/app-secrets'
    `bundle exec bin/hydan kms encrypt --key-alias #{key_alias} --text '#{plaintext}'`
    assert true
  end

  def test_that_kms_decryption_via_stdin_works
    ciphertext = <<-EOS
    {
      "ciphertext": {
        "v": 1,
        "adata": "",
        "ks": 256,
        "ct": "VDrNx9XDJaefv+h0QljKI4923Cpc+helJcdCntoFYhiEMw==",
        "ts": 96,
        "mode": "gcm",
        "cipher": "aes",
        "iter": 100000,
        "iv": "rvHRtCQPCqEoNXex",
        "salt": "lsQGF0/8EN0="
      },
      "data_key": "CiAfOVbeihf6rOyP611suE9ul/zYfZ1DY8k89owZgq5L9BKnAQEBAwB4HzlW3ooX+qzsj+tdbLhPbpf82H2dQ2PJPPaMGYKuS/QAAAB+MHwGCSqGSIb3DQEHBqBvMG0CAQAwaAYJKoZIhvcNAQcBMB4GCWCGSAFlAwQBLjARBAzpI8QPtKgo6lwd4WkCARCAOxpxb1zOM1g0lLWhJorMvOHBuYTZH7klr76I5M9cvXuWMMIDTBamLWCAT92bcSj+H6no0JjyJheus+Fu"
    }
    EOS
    decrypted = `bundle exec echo '#{ciphertext}' | bin/hydan kms decrypt`
    assert decrypted == "This is the plaintext\n"
  end

  # Copies a file from this repo to S3, should succeed silently
  def test_that_s3_copy_works
    src = 'Rakefile'
    dest = 's3://sbi-secrets-qa/Rakefile'
    `bundle exec bin/hydan s3 cp #{src} #{dest}`
    assert true
  end

  # Copies and encrypts a file to S3, should succeed silently
  def test_that_s3_encrypted_copy_works
    src = 'Rakefile'
    dest = 's3://sbi-secrets-qa/Rakefile.enc'
    key_alias = 'alias/sbi/app-secrets'
    `bundle exec bin/hydan s3 cp #{src} #{dest} --key-alias #{key_alias}`
    assert true
  end

  ## Local integration tests

  def test_that_local_encryption_works
    plaintext = 'Testing local encryption logic via CLI'
    key = 'RhZA5KhWaBJqRj1xQwjnQprKziM8p5jsjVcIyB2H5Jg='
    `echo '#{plaintext}' | bundle exec bin/hydan encrypt --master-key #{key}`
    assert true
  end

  def test_that_local_decryption_works
    ciphertext = <<-EOS
    {
      "ciphertext": {
        "v": 1,
        "adata": "",
        "ks": 256,
        "ct": "jwdn0YIQqfc3ge3aFtIC+ersareyjv6+IDSq5QkWPE3E2l47b5puILAzE2L3",
        "ts": 96,
        "mode": "gcm",
        "cipher": "aes",
        "iter": 100000,
        "iv": "UZufP9cL4EOnZdDX",
        "salt": "jWW8jFC5uTE="
      },
      "data_key": "eyJ2IjoxLCJhZGF0YSI6IiIsImtzIjoyNTYsImN0IjoicWZTL2RNcytwaVNPcHBJRFUzUFJiR3hIMUxaMVdxSmladm5GYVdZbFc4TlNPK0hURGorcm1MWk44UFU9IiwidHMiOjk2LCJtb2RlIjoiZ2NtIiwiY2lwaGVyIjoiYWVzIiwiaXRlciI6MTAwMDAwLCJpdiI6IkFUaXJXYWJ4TytQK3NHQW0iLCJzYWx0IjoiZUVlMktrWDI4Yms9In0="
    }
    EOS
    key = 'RhZA5KhWaBJqRj1xQwjnQprKziM8p5jsjVcIyB2H5Jg='
    plaintext = `echo '#{ciphertext}' | bundle exec bin/hydan decrypt --master-key #{key}`
    assert plaintext == "Testing local encryption via CLI\n"
  end

  ## Local unit tests (no CLI/str8 method invocations)

  def test_that_local_encryption_logic_works
    plaintext = %{We gon' TEST THIS}
    symmetric_key = `head -c 32 /dev/urandom`
    client = Hydan::Crypto::EncryptionHelper.new(symmetric_key)
    client.encrypt(plaintext)
    assert true
  end

  def test_that_local_decryption_logic_works
    symmetric_key = Base64.strict_decode64('5n/HCuJLX6miP7L52TxTO+9j3zOcwe5ff9vDuumvxNQ=')
    ciphertext = <<-EOS
    {
      "ciphertext": {
        "v": 1,
        "adata": "",
        "ks": 256,
        "ct": "S2iicbhh24T/ZRQwksPNDy3uWCXLMdyEB255BUg=",
        "ts": 96,
        "mode": "gcm",
        "cipher": "aes",
        "iter": 100000,
        "iv": "EWtJljxsqStkmTmM",
        "salt": "B1ULFsCfJNM="
      },
      "data_key": "eyJ2IjoxLCJhZGF0YSI6IiIsImtzIjoyNTYsImN0IjoiTXFtcWdsdTlYcnJMVTdNaUdsYU03QjlDMlJTWU5ydjFjUWE4TG8vN2pmUFZZU3dBdkVMY0dHQnZwbms9IiwidHMiOjk2LCJtb2RlIjoiZ2NtIiwiY2lwaGVyIjoiYWVzIiwiaXRlciI6MTAwMDAwLCJpdiI6Iis5TytlVUp2WDQ3MUhlVDkiLCJzYWx0IjoiUHFCMUdZdGZHU0E9In0="
    }
    EOS
    client = Hydan::Crypto::DecryptionHelper.new(symmetric_key)
    decrypted = client.decrypt(ciphertext)
    assert decrypted == %{We gon' TEST THIS}
  end

  # Utility logic tests

  def test_that_path_parsing_s3_works
    res = Hydan::S3::S3Helper.parse_path('s3://bogus/a/b/c/object') == Hydan::PathTypes::S3
    assert res
  end

  def test_that_path_parsing_unix_works
    res = Hydan::S3::S3Helper.parse_path('/usr') == Hydan::PathTypes::UNIX
    assert res
  end
end
