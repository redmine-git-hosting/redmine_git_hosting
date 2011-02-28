
module Gitolite

  class GitoliteConfig

    attr_accessor :repos

    def initialize fn
      @fn = fn

      read
    end

    def add_users repo, type, list
      @repos[repo] ||= { :rwp => [], :rw => [], :r => [] }
      @repos[repo][type] = @repos[repo][type] | list

    end


    def write
      File.open(@fn, 'w') do |f|
        @repos.each do |name, users|
          f.puts "        repo\t#{name}"
          f.puts "                RW+    = #{users[:rwp].uniq.join(' ')}" unless users[:rwp].empty?
          f.puts "                RW     = #{users[:rw].uniq.join(' ')}" unless users[:rw].empty?
          f.puts "                R      = #{users[:r].uniq.join(' ')}" unless users[:r].empty?
        end
      end
    end

    private

      def read
        # TODO: error handling
        @repos = {}
        parent = nil
        File.open(@fn, 'r') do |f|
          while s = f.gets do
            if s =~ /repo[ \t]+([-a-zA-Z1-9_]+)/
              parent = $1.chomp
              @repos[parent] = { :r => [], :rw => [], :rwp => [] }
            end

            users = []
            usertype = nil
            if s =~ /RW\+[ \t]+=(.+)/
              usertype = :rwp
              users = $1.split
            end
            if s =~ /RW[ \t]+=(.+)/
              usertype = :rw
              users = $1.split
            end
            if s =~ /R[ \t]+=(.+)/
              usertype = :r
              users = $1.split
            end

            if usertype
              @repos[parent][usertype] = @repos[parent][usertype] | users
            end
          end
        end
      end
  end

end
