require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe RedmineGitHosting::Config do
  GITOLITE_VERSION_2 = [
    'hello redmine_gitolite_admin_id_rsa, this is gitolite v2.3.1-0-g912a8bd-dt running on git 1.7.2.5',
    'hello gitolite_admin_id_rsa, this is gitolite gitolite-2.3.1 running on git 1.8.1.5',
    'hello gitolite_admin_id_rsa, this is gitolite 2.3.1-1.el6 running on git 1.7.1',
    'hello gitolite_admin_id_rsa, this is gitolite 2.2-1 (Debian) running on git 1.7.9.5'
  ]

  GITOLITE_VERSION_3 = [
    'hello redmine_gitolite_admin_id_rsa, this is git@dev running gitolite3 v3.3-11-ga1aba93 on git 1.7.2.5'
  ]

  GITOLITE_VERSION_2.each do |gitolite_version|
    it 'should recognize Gitolite2' do
      version = RedmineGitHosting::Config.find_version(gitolite_version)
      expect(version).to eq 2
    end
  end

  GITOLITE_VERSION_3.each do |gitolite_version|
    it 'should recognize Gitolite3' do
      version = RedmineGitHosting::Config.find_version(gitolite_version)
      expect(version).to eq 3
    end
  end
end
