# frozen_string_literal: true

module RedmineGitHosting::Plugins::Extenders
  class GitAnnexCreator < BaseExtender
    attr_reader :enable_git_annex

    def initialize(repository, **options)
      super(repository, **options)
      @enable_git_annex = options.delete(:enable_git_annex) { false }
    end

    def post_create
      return unless installable?

      if git_annex_installed?
        logger.warn "GitAnnex already exists in path '#{gitolite_repo_path}'"
      else
        install_git_annex
      end
    end

    private

    def installable?
      enable_git_annex? && !recovered?
    end

    def enable_git_annex?
      RedminePluginKit.true? enable_git_annex
    end

    def git_annex_installed?
      directory_exists? File.join(gitolite_repo_path, 'annex')
    end

    def install_git_annex
      sudo_git 'annex', 'init'
    rescue RedmineGitHosting::Error::GitoliteCommandException
      logger.error "Error while enabling GitAnnex for repository '#{gitolite_repo_name}'"
    else
      logger.info "GitAnnex successfully enabled for repository '#{gitolite_repo_name}'"
    end
  end
end
