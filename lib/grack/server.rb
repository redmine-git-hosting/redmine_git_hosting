module Grack
  class Server

    # Override original *service_rpc* method to fix compatibility with Ruby 1.9.3 IO.popen.
    #
    # Between Ruby 1.9 and Ruby 2.0 the method signature has changed :
    # Ruby 1.9.x : popen(cmd, mode="r" [, opt])
    # Ruby 2.x   : popen([env,] cmd, mode="r" [, opt])
    #
    # Hence we need to remove the *popen_env* hash from IO.popen args.
    #
    # See :
    #  - https://github.com/jbox-web/redmine_git_hosting/issues/345
    #  - http://ruby-doc.org//core-1.9.3/IO.html#method-c-popen
    #  - http://ruby-doc.org//core-2.1.0/IO.html#method-c-popen
    #
    # Notes :
    # Given that some people use the Debian package to install Redmine which depends on Ruby 1.9.3
    # this patch will stay until the release of Debian Jessie which will provide Ruby 2.1 .
    # You're still strongly encouraged to move to Ruby 2.x .
    #
    if RUBY_VERSION.split('.')[0] == '1'
      def service_rpc
        return render_no_access if !has_access(@rpc, true)
        input = read_body

        @res = Rack::Response.new
        @res.status = 200
        @res['Content-Type']      = "application/x-git-#{@rpc}-result"
        @res['Transfer-Encoding'] = 'chunked'
        @res['Cache-Control']     = 'no-cache'

        @res.finish do
          command = git_command(%W(#{@rpc} --stateless-rpc #{@dir}))
          IO.popen(command, File::RDWR, popen_options) do |pipe|
            pipe.write(input)
            pipe.close_write
            while !pipe.eof?
              block = pipe.read(8192)           # 8KB at a time
              @res.write encode_chunk(block)    # stream it to the client
            end
            @res.write terminating_chunk
          end
        end
      end
    end


    # Override original *get_git_dir* method because the path is relative
    # and accessed via Sudo.
    #
    def get_git_dir(path)
      path = gitolite_path(path)
      if !directory_exists?(path)
        false
      else
        path # TODO: check is a valid git directory
      end
    end


    # Override original *git_command* method to prefix the command with Sudo and other args.
    #
    def git_command(params)
      git_command_with_sudo(params)
    end


    # Override original *capture* method because the original IO.popen().read let zombie process behind.
    #
    # This method is called :
    #  * to get repository Git config (http.uploadpack || http.receivepack)
    #  * to get repository info refs :
    #    0087deab8f3d612a47e7e153ed21bbc52a480205035a refs/heads/devel report-status delete-refs side-band-64k quiet ofs-delta agent=git/1.9.1
    #  * to get repository refs :
    #    003f91a7b1dad21020e96d52119c585881c02f2fae45 refs/heads/master
    #
    # Note : *service_rpc* also calls IO.popen but pass a block !.
    # Passing a block to IO.popen auto-close the pipe/thread.
    #
    def capture(command)
      # Extract Args
      cmd  = command.shift
      args = command

      begin
        RedmineGitHosting::Utils::Exec.capture(cmd, args)
      rescue => e
        logger.error('Problems while getting SmartHttp params')
      end
    end


    # Override original *popen_options* method.
    # The original one try to chdir before executing the command by
    # passing 'chdir: @dir' option to IO.popen.
    # This is wrong as we can't chdir to Gitolite directory.
    # Notes : this method is called in *service_rpc* (not overriden)
    #
    def popen_options
      { unsetenv_others: true }
    end


    # Override original *popen_env* method.
    # The original one passes useless arg (GL_ID) to IO.popen.
    # Notes : this method is called in *service_rpc* (not overriden)
    #
    def popen_env
       { 'PATH' => ENV['PATH'] }
    end


    private


      def gitolite_path(path)
        File.join(RedmineGitHosting::Config.gitolite_global_storage_dir, RedmineGitHosting::Config.gitolite_redmine_storage_dir, path)
      end


      def directory_exists?(dir)
        RedmineGitHosting::Commands.sudo_dir_exists?(dir)
      end


      # We sometimes need to add *--git-dir* arg to Git command otherwise
      # Git looks for the repository in the current path.
      def git_command_with_sudo(params)
        if command_require_chdir?(params.last)
          git_command_with_chdir.concat(params)
        else
          git_command_without_chdir.concat(params)
        end
      end


      def command_require_chdir?(cmd)
        cmd == 'update-server-info' || cmd == 'http.receivepack'  || cmd == 'http.uploadpack'
      end


      def git_command_without_chdir
        RedmineGitHosting::Commands.sudo_git_cmd(smart_http_args)
      end


      def git_command_with_chdir
        RedmineGitHosting::Commands.sudo_git_args_for_repo(@dir, smart_http_args)
      end


      def smart_http_args
        [
          'env',
          "GL_LIBDIR=#{RedmineGitHosting::Config.gitolite_lib_dir_path}",
          "GL_REPO=#{repository_object.gitolite_repository_name}",
          "GL_USER=#{@env['REMOTE_USER']}"
        ]
      end


      def logger
        RedmineGitHosting.logger
      end


      def repository_object
        @repo ||= Repository::Xitolite.find_by_path(@dir, loose: true)
      end

  end
end
