module Hydan
  module IO
    ENV_LINE_REGEX = /(.*?)=(.*)/

    # Reads text from STDIN, or uses the value supplied with
    # --plaintext, if any. Returns the text.
    # @return [String]
    def handle_input(options)
      text = options[:text].join ' ' if options[:text]
      unless options[:text]
        text = ''
        text << $LAST_READ_LINE while $stdin.gets # unless $stdin.tty?
      end
      # raise ArgumentError.new('No plaintext specified') if text.empty?
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

    # Handles the output phase for file encryption/decryption.
    # This only concerns the encrypted data key, since file
    # encryption automatically assumes that an output file is being
    # used (by the library). The input encrypted_data_key is expected
    # to be a binary key, *not* Base64 encoded.
    def handle_key_output(encrypted_data_key_blob, out_key_file = nil)
      File.open(out_key_file, 'wb') {
        |f| f.write encrypted_data_key_blob
      } if out_key_file
      puts "Data key (Base64): #{Base64.strict_encode64(encrypted_data_key_blob)}" unless out_key_file
    end

  end
end
