class GitHosting::CustomHook

  attr_reader :repo_path
  attr_reader :refs


  def initialize(repo_path, refs)
    @repo_path = repo_path
    @refs      = refs
  end


  def exec

  end

end


# ## Execute extra hooks
# extra_hooks = get_extra_hooks
# if extra_hooks.length > 0
#   logger("Calling additional post-receive hooks...", false, true)
#   call_extra_hooks(extra_hooks, stdin_copy)
# end

# def get_executables(directory)
#   executables = []
#   if File.directory?(directory)
#     logger("  - Found folder: #{directory}", true, true)
#     Dir.foreach(directory) do |item|
#       next if item == '.' or item == '..'
#       # Use full relative path
#       path = "#{directory}/#{item}"
#       # Test if the file is executable
#       if File.executable?(path)
#         logger("  - Found executable file: #{path} ...", true, false)
#         # Remember it, if so
#         executables.push(path)
#         logger(" [added]", true, true)
#       end
#     end
#   else
#     logger("  - Folder not found: #{directory}", true, true)
#   end
#   return executables
# end


# def call_extra_hooks(extra_hooks, stdin)
#   # Call each exectuble found with the parameters we got
#   extra_hooks.each do |extra_hook|
#     logger("  - Executing extra hook '#{extra_hook}'")

#     IO.popen("#{extra_hook}", "w+") do |pipe|
#       begin
#         pipe.puts stdin
#         pipe.close_write
#         logger("#{pipe.read}")
#       rescue => e
#         logger("Error while executing hook #{extra_hook}", false, true)
#         logger("#{e.message}", true, true)
#       end
#     end
#   end
# end


# def get_extra_hooks
#   # Get global extra hooks
#   logger("Looking for additional global post-receive hooks...", true, true)
#   global_extra_hooks = get_executables("hooks/post-receive.d")
#   if global_extra_hooks.length == 0
#     logger("  - No global hooks found", true, true)
#   end

#   logger("", true, true)

#   # Get local extra hooks
#   logger("Looking for additional local post-receive hooks...", true, true)
#   local_extra_hooks = get_executables("hooks/post-receive.local.d")
#   if local_extra_hooks.length == 0
#     logger("  - No local hooks found", true, true)
#   end

#   logger("", true, true)

#   # Join both results and return result
#   result = []
#   result.concat(global_extra_hooks)
#   result.concat(local_extra_hooks)
#   return result
# end
