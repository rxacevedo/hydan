require 'test_helper'

class HydanCITest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Hydan::VERSION
  end

  ## Local integration tests

  def test_that_local_encryption_works
    plaintext = 'Testing local encryption logic via CLI'
    key = 'RhZA5KhWaBJqRj1xQwjnQprKziM8p5jsjVcIyB2H5Jg='
    `echo '#{plaintext}' | hydan encrypt --master-key #{key}`
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
    plaintext = `echo '#{ciphertext}' | hydan decrypt --master-key #{key}`
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
end
