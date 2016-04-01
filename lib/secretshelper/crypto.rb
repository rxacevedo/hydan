module SecretsHelper
  module Crypto
    ENV_LINE_REGEX = /(.*?)=(.*)/
    DEFAULT_CIPHER = 'AES-256-CBC'

    # Reads text from STDIN, or uses the value supplied with
    # --plaintext, if any. Returns the text.
    # @return [String]
    def handle_stdin
      text = options[:plaintext].join ' ' if options[:plaintext]
      unless options[:plaintext]
        text = ''
        text << $LAST_READ_LINE while $stdin.gets
      end
      text
    end

    # Output phase of the encryption process, prints output
    # to STDOUT or uses the value supplied with --out to write
    # output to a file, if any.
    # @return [Nil]
    def handle_output(json)
      File.open(options[:out], 'w') { |f| f.write json } if options[:out]
      puts json unless options[:out]
      nil
    end

  end
end
