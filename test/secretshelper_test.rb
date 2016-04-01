require 'test_helper'

class SecretsHelperTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::SecretsHelper::VERSION
  end

  def test_that_kms_encryption_via_stdin_works
    plaintext = 'This is the plaintext'
    key_alias = 'alias/sbi/app-secrets'
    `echo #{plaintext} | bundle exec bin/secretshelper encrypt --key-alias #{key_alias}`
    assert true
  end

  def test_that_kms_encryption_via_plaintext_flag_works
    plaintext = 'CLI plaintext 1234567890 --==!@#$%^&*()_+'
    key_alias = 'alias/sbi/app-secrets'
    `bundle exec bin/secretshelper encrypt --key-alias #{key_alias} --plaintext '#{plaintext}'`
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
    decrypted = `bundle exec echo '#{ciphertext}' | bin/secretshelper decrypt`
    assert decrypted == "This is the plaintext\n"
  end

  def test_that_local_encryption_logic_works
    plaintext = %{We gon' TEST THIS}
    symmetric_key = `head -c 32 /dev/urandom`
    client = SecretsHelper::Crypto::EncryptionHelper.new(symmetric_key)
    client.encrypt(plaintext)
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
    client = SecretsHelper::Crypto::DecryptionHelper.new(symmetric_key)
    decrypted = client.decrypt(ciphertext)
    assert decrypted == %{We gon' TEST THIS}
  end

  def test_that_path_parsing_s3_works
    res = SecretsHelper::S3Helper.parse_path('s3://bogus/a/b/c/object') == SecretsHelper::PathTypes::S3
    assert res
  end

  def test_that_path_parsing_unix_works
    res = SecretsHelper::S3Helper.parse_path('/usr') == SecretsHelper::PathTypes::UNIX
    assert res
  end
end
