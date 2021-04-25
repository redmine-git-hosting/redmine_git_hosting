# frozen_string_literal: true

module RedmineGitHosting
  module RecycleBin
    extend self

    delegate :content, to: :recycle_bin

    def delete_expired_content(expiration_time = default_expiration_time)
      recycle_bin.delete_expired_content expiration_time
    end

    def delete_content(content_list = [])
      recycle_bin.delete_content content_list
    end

    delegate :move_object_to_recycle, to: :recycle_bin

    delegate :restore_object_from_recycle, to: :recycle_bin

    private

    def default_expiration_time
      RedmineGitHosting::Config.gitolite_recycle_bin_expiration_time
    end

    def recycle_bin
      @recycle_bin ||= RecycleBin::Manager.new RedmineGitHosting::Config.recycle_bin_dir
    end
  end
end
