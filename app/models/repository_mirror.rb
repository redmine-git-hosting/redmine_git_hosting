class RepositoryMirror < ActiveRecord::Base
	STATUS_ACTIVE = 1
	STATUS_INACTIVE = 0

	belongs_to :project

	validates_uniqueness_of :url, :scope => [:project_id]
	validates_presence_of :project_id, :url

	validates_associated :project

	named_scope :active, {:conditions => {:active => RepositoryMirror::STATUS_ACTIVE}}
	named_scope :inactive, {:conditions => {:active => RepositoryMirror::STATUS_INACTIVE}}

	def to_s
		return File.join("#{project.identifier}-#{url}")
	end

	def push
		repo_path = GitHosting.repository_path(project)
		shellout = %x[ echo 'cd "#{repo_path}" ; env GIT_SSH=~/.ssh/run_gitolite_admin_ssh git push --mirror "#{url}" 2>&1' | #{GitHosting.git_user_runner} "bash" ]
		push_failed = ($?.to_i!=0) ? true : false

		err_output = push_failed ? "" : ""
		if push_failed
			ms = " #{mirror.url} push error "
			nr = (70-ms.length)/2
			GitHosting.logger.debug "Failed:\n%{nrs} #{ms} %{nrs}\n#{shellout}%{nre} #{ms} %{nre}\n" % {:nrs => ">"*nr, :nre => "<"*nr}
			err_output = err_output + ("%{nrs} #{ms} %{nrs}\n" % {:nrs => ">"*nr})
			err_output = err_output + "#{shellout}"
			err_output = err_output + ("%{nre} #{ms} %{nre}\n" % {:nre => "<"*nr})
		end
		err_output
	end

end
