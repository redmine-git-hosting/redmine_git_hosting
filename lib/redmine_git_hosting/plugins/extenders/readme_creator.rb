# frozen_string_literal: true

require 'rugged'

module RedmineGitHosting::Plugins::Extenders
  class ReadmeCreator < BaseExtender
    attr_reader :create_readme_file

    def initialize(repository, **options)
      super(repository, **options)
      @create_readme_file = options.delete(:create_readme_file) { false }
    end

    def post_create
      return unless installable?

      if repository_empty?
        do_create_readme_file
      else
        logger.warn "Repository is not empty, cannot create README file in path '#{gitolite_repo_path}'"
      end
    end

    private

    def installable?
      create_readme_file? && !recovered?
    end

    def create_readme_file?
      RedminePluginKit.true? create_readme_file
    end

    def do_create_readme_file
      logger.info "Creating README file for repository '#{gitolite_repo_name}'"
      temp_dir = Dir.mktmpdir

      begin
        ## Clone repository
        repo = clone_repo temp_dir

        ## Create file
        index = create_file repo

        ## Create commit
        create_commit repo, index

        ## Push
        push_commit repo
      rescue StandardError => e
        logger.error "Error while creating README file for repository '#{gitolite_repo_name}'"
        logger.error e.message
      else
        logger.info 'README file successfully created.'
      ensure
        FileUtils.rm_rf temp_dir
      end
    end

    def clone_repo(temp_dir)
      Rugged::Repository.clone_at repository.ssh_url, temp_dir, credentials: credentials
    end

    def create_file(repo)
      oid = repo.write "## #{gitolite_repo_name}", :blob
      index = repo.index
      index.add path: 'README.md', oid: oid, mode: 0o100644
      index
    end

    def create_commit(repo, index)
      commit_tree = index.write_tree repo
      Rugged::Commit.create(repo,
                            author: commit_author,
                            committer: commit_author,
                            message: 'Add README file',
                            parents: repo.empty? ? [] : [repo.head.target].compact,
                            tree: commit_tree,
                            update_ref: 'HEAD')
    end

    def push_commit(repo)
      repo.push 'origin', [remote_branch], credentials: credentials
    end

    def remote_branch
      "refs/heads/#{git_default_branch}"
    end

    def credentials
      Rugged::Credentials::SshKey.new(
        username: RedmineGitHosting::Config.gitolite_user,
        publickey: RedmineGitHosting::Config.gitolite_ssh_public_key,
        privatekey: RedmineGitHosting::Config.gitolite_ssh_private_key
      )
    end

    def commit_author
      @commit_author ||= {
        email: RedmineGitHosting::Config.git_config_username,
        name: RedmineGitHosting::Config.git_config_email,
        time: Time.now
      }
    end
  end
end
