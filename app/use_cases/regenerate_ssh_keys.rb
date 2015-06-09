class RegenerateSshKeys
  unloadable

  attr_reader :bypass_sidekiq


  def initialize(opts = {})
    @bypass_sidekiq = opts.delete(:bypass_sidekiq){ false }
  end


  def call
    GitolitePublicKey.all.each do |ssh_key|
      GitoliteAccessor.destroy_ssh_key(ssh_key, bypass_sidekiq: bypass_sidekiq)
      ssh_key.reset_identifiers
      GitoliteAccessor.create_ssh_key(ssh_key, bypass_sidekiq: bypass_sidekiq)
    end
  end

end
