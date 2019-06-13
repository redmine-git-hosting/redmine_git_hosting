module RedmineGitHosting
  module RecycleBin
    extend self

    def content
      recycle_bin.content
    end

    def delete_expired_content(expiration_time = default_expiration_time)
      recycle_bin.delete_expired_content(expiration_time)
    end

    def delete_content(content_list = [])
      recycle_bin.delete_content(content_list)
    end

    def move_object_to_recycle(object_name, source_path)
      recycle_bin.move_object_to_recycle(object_name, source_path)
    end

    def restore_object_from_recycle(object_name, target_path)
      recycle_bin.restore_object_from_recycle(object_name, target_path)
    end

    private

    def default_expiration_time
      RedmineGitHosting::Config.gitolite_recycle_bin_expiration_time
    end

    def recycle_bin
      @recycle_bin ||= RecycleBin::Manager.new(RedmineGitHosting::Config.recycle_bin_dir)
    end
  end
end
