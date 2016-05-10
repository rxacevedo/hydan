# Hydan

Hydan is a command-line utility for encrypting and decrypting text and/or files. In addition to local crypto operations, Hydan can also defer to Amazon KMS for symmetric master keys. S3 uploads/downloads are also supported, and can leverage KMS for encryption/decryption.

## TODO:

- [ ] Support multi-part uploads for S3
- [ ] Support SSE for S3 uploads

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hydan'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hydan

## Disclaimer

Hydan is open-source software - **USE AT YOUR OWN RISK!** The authors and all affiliates assume no responsibility for issues encountered with the use of of this software.

## Usage

### Local text encryption

Local text encryption returns a JSON object containing the cihpertext and randomly-generated data key. Plaintext can be piped into STDIN or passed on the CLI via the `--text` flag.

```
# We'll grab 256 random bits for the master key
KEY=$(head -c 32 /dev/urandom | base64)
echo 'A secret on STDIN' | hydan encrypt --master-key $KEY
{
  "ciphertext": {
    "v": 1,
    "adata": "",
    "ks": 256,
    "ct": "8VmGeR6+rtznK6Lu8vmr99PFmbxfu6FcyzWyiU17",
    "ts": 96,
    "mode": "gcm",
    "cipher": "aes",
    "iter": 100000,
    "iv": "8Pj1RuenaRqV5BRc",
    "salt": "mXfzMTw89lE="
  },
  "data_key": "eyJ2IjoxLCJhZGF0YSI6IiIsImtzIjoyNTYsImN0IjoiVlVDclRLUTV2WVpBMGFuTW9NTUQzWS9OQ0NYUkF0SWFpc3JYcFI1THVraHptUE1WeTVqRzBsbFJsM1k9IiwidHMiOjk2LCJtb2RlIjoiZ2NtIiwiY2lwaGVyIjoiYWVzIiwiaXRlciI6MTAwMDAwLCJpdiI6ImRUeTBPVUt2a3plaThkdnEiLCJzYWx0Ijoib1BQTXF2U1ZCN2c9In0="
}
```

### Local decryption
```
KEY=$(head -c 32 /dev/urandom | base64)
echo 'The Krabby Patty secret recipe IS...' | hydan encrypt --master-key $KEY | hydan decrypt --master-key $KEY
The Krabby Patty secret recipe IS...

hydan encrypt --master-key $KEY --text 'This also works' | hydan decrypt --master-key $KEY
This also works
```

#### Env files
A common use case (actually, the reason that this utility was even written) for setting up credentials is through environment variables. To accomodate this, `hydan` supports `--env-formatted` text input. When this flag is passed in, K/V pairs are parsed from each line, and the value (V) is encrypted. This allows for a file to be partially encrypted in a way that hides sensitive information, while still allowing an administrator or operator to understand what the file is for.

```
KEY=$(head -c 32 /dev/urandom | base64)
cat test.env
FOO=bar
BAR=baz
BAZ=bat
A=B
ENV=ENV
K=V

hydan encrypt --env-formatted --master-key $KEY < test.env
FOO={"ciphertext":{"v":1,"adata":"","ks":256,"ct":"fnu8Ulyr5JLQArNp5rLz","ts":96,"mode":"gcm","cipher":"aes","iter":100000,"iv":"MOZzAZ/9qtHMCr/t","salt":"37WkVaQQxDA="},"data_key":"eyJ2IjoxLCJhZGF0YSI6IiIsImtzIjoyNTYsImN0IjoiMjFjZ21kM21PbUxBL20xdUt1bDJHNXV5VUhkaXFLQlZhSGlCQ2NzVnczbG5mUnY0Y05SSHRRMFFWVUE9IiwidHMiOjk2LCJtb2RlIjoiZ2NtIiwiY2lwaGVyIjoiYWVzIiwiaXRlciI6MTAwMDAwLCJpdiI6IkNRSkNJanlKVW9pR0kzbHQiLCJzYWx0IjoibS94a2trSm85Nzg9In0="}
BAR={"ciphertext":{"v":1,"adata":"","ks":256,"ct":"F9oTm34xCj5Ke68hB+rL","ts":96,"mode":"gcm","cipher":"aes","iter":100000,"iv":"uXP2BC9wyCyJiFy6","salt":"DLDWXIxsbv8="},"data_key":"eyJ2IjoxLCJhZGF0YSI6IiIsImtzIjoyNTYsImN0IjoiYWRRdC9reFQzS2FwSG9FWFlzclJ6bmhqdlcxYVVGdWtQd0xRZXJZTUdTMDF0WFY1RSsyRkRBZndndDA9IiwidHMiOjk2LCJtb2RlIjoiZ2NtIiwiY2lwaGVyIjoiYWVzIiwiaXRlciI6MTAwMDAwLCJpdiI6Ii9SbnFWWkZTR0EwQkw0UEEiLCJzYWx0IjoiSHYxeEd0eTZLcTQ9In0="}
BAZ={"ciphertext":{"v":1,"adata":"","ks":256,"ct":"VZ3qtRrRYVRIhJ3qIyku","ts":96,"mode":"gcm","cipher":"aes","iter":100000,"iv":"Ib19BVMCP3VqoeQ+","salt":"9DRsMkbtRvo="},"data_key":"eyJ2IjoxLCJhZGF0YSI6IiIsImtzIjoyNTYsImN0IjoieDcrdklNazBCYThnbWlMMGZ3WHE0TGpMVkNUYVBjaFhZWDFSUUkrL2oraGlBR2V0b3BxS0w2ZG5CbUU9IiwidHMiOjk2LCJtb2RlIjoiZ2NtIiwiY2lwaGVyIjoiYWVzIiwiaXRlciI6MTAwMDAwLCJpdiI6IkgzTXlEcXB4SXUrMGNoVTgiLCJzYWx0IjoiN0RSYzZmWkZWcFE9In0="}
A={"ciphertext":{"v":1,"adata":"","ks":256,"ct":"6Hqk69PLuImnpTWSjw==","ts":96,"mode":"gcm","cipher":"aes","iter":100000,"iv":"oy5lea/k99nsZz8/","salt":"yYrMK6MbXfQ="},"data_key":"eyJ2IjoxLCJhZGF0YSI6IiIsImtzIjoyNTYsImN0IjoiN3gySUZIZmk2NjB6VnpqWDd4MjJqTUlHeXdZclRuY3E1cGdOcHU1RTB2R2I3MWMvbVp3ZjR0cUxtSk09IiwidHMiOjk2LCJtb2RlIjoiZ2NtIiwiY2lwaGVyIjoiYWVzIiwiaXRlciI6MTAwMDAwLCJpdiI6IkJ1a1lBRGJhaHVvcDJuM2YiLCJzYWx0IjoiKzhVOWhiaUtCRmc9In0="}
ENV={"ciphertext":{"v":1,"adata":"","ks":256,"ct":"FQfnNaMl936fhZo3Ykrx","ts":96,"mode":"gcm","cipher":"aes","iter":100000,"iv":"12QqZqCxkvMbagzo","salt":"A3YypAcXUIQ="},"data_key":"eyJ2IjoxLCJhZGF0YSI6IiIsImtzIjoyNTYsImN0IjoiL2xpM0NnaG5BUmJCM3NmMlA5aTNLRXd3eFBITk9HQVFTdFBzVHFWUXRIZGRBRHNOL0wzV1Jrc3dIbGM9IiwidHMiOjk2LCJtb2RlIjoiZ2NtIiwiY2lwaGVyIjoiYWVzIiwiaXRlciI6MTAwMDAwLCJpdiI6ImFEK1dIZEwwWnlzbmJ5d0QiLCJzYWx0IjoiZ3hlL3dYVU9GRmM9In0="}
K={"ciphertext":{"v":1,"adata":"","ks":256,"ct":"wpSRhDud1zqxhlvqdQ==","ts":96,"mode":"gcm","cipher":"aes","iter":100000,"iv":"9WnyuuOx2q6J/KCR","salt":"kZNxqsQE8o0="},"data_key":"eyJ2IjoxLCJhZGF0YSI6IiIsImtzIjoyNTYsImN0IjoiWHpsSWEzZEVoeWNHQ0lDQTJvU2xZem93SFZUeU1CVGUyb1dwNkVZcm9JamR4azg4SnVXci9USlIxaUE9IiwidHMiOjk2LCJtb2RlIjoiZ2NtIiwiY2lwaGVyIjoiYWVzIiwiaXRlciI6MTAwMDAwLCJpdiI6IkUxdGNNT0E0YkpBSzlEdGMiLCJzYWx0IjoibzRZcjQ5U3NhVU09In0="}

# --env-formatted plays nicely with pipes too
hydan encrypt --env-formatted --master-key $KEY < test.env | hydan decrypt --env-formatted --master-key $KEY
FOO=bar
BAR=baz
BAZ=bat
A=B
ENV=ENV
K=V

# This can easily be used to construct export statements to be evaluated via eval
hydan encrypt --env-formatted --master-key $KEY < test.env | hydan decrypt --env-formatted --master-key $KEY | awk '{ print "export " $1 }'
export FOO=bar
export BAR=baz
export BAZ=bat
export A=B
export ENV=ENV
export K=V
```

#### Large files
When files are too large to read into memory, use the `--in` and `--out` flags. This will prompt `hydan` to use logic that reads and encrypts the file line-by-line, as opposed to "slurping" the file beforehand. This also implies that it's not worth Base64 encoding the encrypted output, since it will also be large. Because of this, encryption that uses the `--in` flag saves it's output in binary instead of Base64.

```
# Make a huge file
mkfile -n 10g ~/Desktop/LargeTestFile

hydan encrypt --in ~/Desktop/LargeTestFile --out ~/Desktop/LargeTestFile.bin --master-key $KEY
Data key (Base64): U2FsdGVkX18NG/y8sEFGyop79njj0R9omH+/UZ3Ijy1c8nYACE2UQt1NMvSL2Rh9GH4p+TSEZxSMqqWqzg7/Kw==

# We use the encrypted data key generated by the program in order to decrypt the file
# If `--key-out` is specified, the key will be saved to the supplied path instead of
# being printed to STDOUT.
hydan decrypt --in ~/Desktop/LargeTestFile.bin --out ~/Desktop/LargeTestFile.decrypted --master-key $KEY --data-key U2FsdGVkX18NG/y8sEFGyop79njj0R9omH+/UZ3Ijy1c8nYACE2UQt1NMvSL2Rh9GH4p+TSEZxSMqqWqzg7/Kw==

# Original
shasum -a 256 ~/Desktop/LargeTestFile
732377e7f4a2abdc13ddfa1eb4c9c497fd2a2b294674d056cf51581b47dd586d  /Users/roberto/Desktop/LargeTestFile

# Decrypted
shasum -a 256 ~/Desktop/LargeTestFile.decrypted
732377e7f4a2abdc13ddfa1eb4c9c497fd2a2b294674d056cf51581b47dd586d  /Users/roberto/Desktop/LargeTestFile.decrypted
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/hydan.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

