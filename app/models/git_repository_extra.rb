require 'openssl'
require 'digest/sha2'
require 'active_support/base64'
require 'active_support/secure_random'

class GitRepositoryExtra < ActiveRecord::Base

	belongs_to :repository, :class_name => 'Repository', :foreign_key => 'repository_id'

	#validates_presence_of :repository_id, :key, :ivector, :git_http, :git_daemon
	validates_associated :repository


	def after_initialize
		generate if self.repository.nil?
	end


	def check_key(encoded_key)
		begin
			c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
			c.decrypt
			c.key = read_attribute(:key)
			c.iv = read_attribute(:ivector)
			decoded = c.update(ActiveSupport::Base64.decode64(encoded_key))
			decoded << c.final
			return read_attribute(:key) == decoded
		rescue Exception=>e
			GitHosting.logger.error("Check key failed for #{self.repository.project.identifier}'s repository hook: #{e.to_s}")
			return false
		end
	end

	def encode_key
		c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
		c.encrypt
		c.key = read_attribute(:key)
		c.iv = read_attribute(:ivector)
		encrypted =  c.update(read_attribute(:key))
		encrypted << c.final
		return ActiveSupport::Base64.encode64s(encrypted)
	end

	def generate
		write_attribute(:key, Digest::SHA1.hexdigest(ActiveSupport::SecureRandom.random_bytes(16)).unpack('a2'*32).map{|x| x.hex}.pack('c'*32))
		write_attribute(:ivector, Digest::SHA1.hexdigest(ActiveSupport::SecureRandom.random_bytes(16)).unpack('a2'*32).map{|x| x.hex}.pack('c'*32))
		self.save
	end

end
