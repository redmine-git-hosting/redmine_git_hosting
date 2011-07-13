require 'open3'



#
# Copyright (c) 2011 Pedro Algarvio
# Copyright (c) 2010 Kah Seng Tay - Gitolite modifications
#
# Copyright (c) 2009 Jakob Skjerning - Original
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
#
# Originaly found on the redmine_gitolite_hook:
#   https://github.com/kahseng/redmine_gitolite_hook

class GitoliteHookController < ApplicationController

	skip_before_filter :verify_authenticity_token, :check_if_login_required
	def index
		repository = find_repository

		# Fetch the changes from Gitolite
		update_repository(repository)

		# Fetch the new changesets into Redmine
		repository.fetch_changesets

		render(:text => 'OK')
	end

	private

	def exec(command)
		logger.debug { "GitoliteHook: Executing command: '#{command}'" }
		stdin, stdout, stderr = Open3.popen3(command)

		output = stdout.readlines.collect(&:strip)
		errors = stderr.readlines.collect(&:strip)

		logger.debug { "GitoliteHook: Output from git:" }
		logger.debug { "GitoliteHook:  * STDOUT: #{output}"}
		logger.debug { "GitoliteHook:  * STDERR: #{errors}"}
	end

	# Fetches updates from the remote repository
	def update_repository(repository)
		command = "cd '#{repository.url}' && git fetch origin && git reset --soft refs/remotes/origin/master"
		exec(command)
	end

	# Gets the project identifier from the querystring parameters.
	def get_identifier
		identifier = params[:project_id]
		# TODO: Can obtain 'oldrev', 'newrev', 'refname', 'user' in POST params for further action if needed.
		raise ActiveRecord::RecordNotFound, "Project identifier not specified" if identifier.nil?
		return identifier
	end

	# Finds the Redmine project in the database based on the given project identifier
	def find_project
		identifier = get_identifier
		project = Project.find_by_identifier(identifier.downcase)
		raise ActiveRecord::RecordNotFound, "No project found with identifier '#{identifier}'" if project.nil?
		return project
	end

	# Returns the Redmine Repository object we are trying to update
	def find_repository
		project = find_project
		repository = project.repository
		raise TypeError, "Project '#{project.to_s}' ('#{project.identifier}') has no repository" if repository.nil?
		raise TypeError, "Repository for project '#{project.to_s}' ('#{project.identifier}') is not a Git repository" unless repository.is_a?(Repository::Git)
		return repository
	end

end
