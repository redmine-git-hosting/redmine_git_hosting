#!/usr/bin/env ruby

# This file was placed here by Redmine Git Hosting. It makes sure that your pushed commits
# will be processed properly.

refs = ARGF.read
repo_path = Dir.pwd

require_relative 'lib/git_hosting/http_helper'
require_relative 'lib/git_hosting/hook_logger'
require_relative 'lib/git_hosting/config'
require_relative 'lib/git_hosting/post_receive'
require_relative 'lib/git_hosting/custom_hook'

if GitHosting::PostReceive.new(repo_path, refs).exec && GitHosting::CustomHook.new(repo_path, refs).exec
  exit 0
else
  exit 1
end
