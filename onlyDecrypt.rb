# frozen_string_literal: true

require 'openssl'
require 'digest/sha2'

class Crypto # :nodoc:
  def self.decrypt(cipher_hex)
    return if cipher_hex.empty?

    crypto = start(:decrypt)
    cipher_text = cipher_hex.gsub(/(..)/) {|h| h.hex.chr }
    plain_text = crypto.update(cipher_text)
    plain_text << crypto.final
    plain_text
  end

  def self.start(mode)
    crypto = OpenSSL::Cipher.new('aes-256-ecb').send(mode)
    crypto.key = Digest::MD5.hexdigest("63a0e23a1d70a7de0b770296d84082e2")
    crypto
  end

  private_class_method :start
end

puts "Please Enter User Value"
value = gets.chomp
puts "#{Crypto.decrypt(value)}"
