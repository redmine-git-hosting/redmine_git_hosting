module GitolitePublicKeys
  class GenerateIdentifier

    DEPLOY_PSEUDO_USER = 'deploy_key'

    attr_reader :public_key
    attr_reader :user
    attr_reader :skip_auto_increment


    def initialize(public_key, user, opts = {})
      @public_key          = public_key
      @user                = user
      @skip_auto_increment = opts.delete(:skip_auto_increment) { false }
    end


    class << self

      def call(public_key, user, opts = {})
        new(public_key, user, opts).call
      end

    end


    # Returns the unique identifier for this key based on the key_type
    #
    # For user public keys, this simply is the user's gitolite_identifier.
    # For deployment keys, we use an incrementing number.
    #
    def call
      if public_key.user_key?
        set_identifier_for_user_key
      elsif public_key.deploy_key?
        set_identifier_for_deploy_key
      end
    end


    private


      def set_identifier_for_user_key
        tag = public_key.title.gsub(/[^0-9a-zA-Z]/, '_')
        [user.gitolite_identifier, '@', 'redmine_', tag].join
      end


      # Fix https://github.com/jbox-web/redmine_git_hosting/issues/288
      # Getting user deployment keys count is not sufficient to assure uniqueness of
      # deployment key identifier. So we need an 'external' counter to increment the global count
      # while a key with this identifier exists.
      #
      def set_identifier_for_deploy_key
        count = 0
        begin
          key_id = generate_deploy_key_identifier(count)
          count += 1
        end while user.gitolite_public_keys.deploy_key.map(&:owner).include?(key_id.split('@')[0])
        key_id
      end


      def generate_deploy_key_identifier(count)
        key_count = 1 + count
        key_count += user.gitolite_public_keys.deploy_key.length unless skip_auto_increment
        [user.gitolite_identifier, '_', DEPLOY_PSEUDO_USER, '_', key_count, '@', 'redmine_', DEPLOY_PSEUDO_USER, '_', key_count].join
      end

  end
end
