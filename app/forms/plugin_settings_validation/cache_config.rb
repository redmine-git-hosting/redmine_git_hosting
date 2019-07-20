module PluginSettingsValidation
  module CacheConfig
    extend ActiveSupport::Concern

    included do
      # Gitolite Cache Config
      add_accessor :gitolite_cache_max_time,
                   :gitolite_cache_max_size,
                   :gitolite_cache_max_elements,
                   :gitolite_cache_adapter

      validates :gitolite_cache_max_time,     presence: true, numericality: { only_integer: true }
      validates :gitolite_cache_max_size,     presence: true, numericality: { only_integer: true }
      validates :gitolite_cache_max_elements, presence: true, numericality: { only_integer: true }
      validates :gitolite_cache_adapter,      presence: true, inclusion: { in: GitCache.adapters }
    end
  end
end
