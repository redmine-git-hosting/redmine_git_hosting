#!/usr/bin/env ruby

require 'digest/sha1'
require 'net/http'
require 'net/https'
require 'uri'


###############################
##                           ##
##         FUNCTIONS         ##
##                           ##
###############################

def logger(message, debug_only = false, with_newline = true)
  if $debug || (!debug_only)
    print message + (with_newline ? "\n" : "")
  end
end


def load_gitolite_vars
  redmine_vars_hash = {}

  redmine_var_names = [
    "redminegitolite.redmineurl",
    "redminegitolite.projectid",
    "redminegitolite.repositoryid",
    "redminegitolite.repositorykey",
    "redminegitolite.debugmode",
    "redminegitolite.asyncmode",
  ]

  redmine_var_names.each do |var_name|
    var_value = get_gitolite_config(var_name)

    if var_value.to_s == ""
      # Allow blank repositoryid (as default)
      if var_name != "redminegitolite.repositoryid"
        logger("", false, true)
        logger("Repository does not have '#{var_name}' set, exiting...", false, true)
        logger("", false, true)
        exit 1
      end
    else
      var_name = var_name.gsub(/^.*\./, "")
      redmine_vars_hash[var_name] = var_value
    end
  end

  return redmine_vars_hash
end


def get_gitolite_config(varname)
  (%x[git config #{varname}]).chomp.strip
end


def run_http_query(url_str, params)
  params = get_http_params(params)

  url  = URI(url_str)
  http = Net::HTTP.new(url.host, url.port)
  http.open_timeout = 5
  http.read_timeout = 10

  if url.scheme == 'https'
    http.use_ssl = true
    http.ssl_version = :SSLv3 if http.respond_to? :ssl_version
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  request = Net::HTTP::Post.new(url.request_uri)
  request = set_form_data(request, params)

  success = false

  begin
    http.request(request) do |response|
      if response.code.to_i == 200
        success = true
        response.read_body do |body_frag|
          logger(body_frag, false, false)
        end
      else
        success = false
      end
    end
  rescue => e
    logger("HTTP_ERROR : #{e.message}", true, true)
    success = false
  end

  return success
end


def get_http_params(redmine_vars_hash)
  clear_time = Time.new.utc.to_i.to_s
  params = { "clear_time" => clear_time, "encoded_time" => Digest::SHA1.hexdigest(clear_time.to_s + redmine_vars_hash["repositorykey"]) }
  redmine_vars_hash.each_key do |key|
    if key != "repositorykey"
      params[key] = redmine_vars_hash[key]
    end
  end
  return params
end


# Need to do this ourselves, because 1.8.7 ruby is broken
def set_form_data(request, params)
  request.body = params.map {|key, value|
    if value.instance_of?(Array)
      value.map {|e| "#{urlencode(key.to_s)}=#{urlencode(e.to_s)}"}.join('&')
    else
      "#{urlencode(key.to_s)}=#{urlencode(value.to_s)}"
    end
  }.join('&')

  request.content_type = 'application/x-www-form-urlencoded'

  return request
end


def urlencode(string)
  URI.encode(string, /[^a-zA-Z0-9_\.\-]/)
end


def get_extra_hooks
  # Get global extra hooks
  logger("Looking for additional global post-receive hooks...", true, true)
  global_extra_hooks = get_executables("hooks/post-receive.d")
  if global_extra_hooks.length == 0
    logger("  - No global hooks found", true, true)
  end

  logger("", true, true)

  # Get local extra hooks
  logger("Looking for additional local post-receive hooks...", true, true)
  local_extra_hooks = get_executables("hooks/post-receive.local.d")
  if local_extra_hooks.length == 0
    logger("  - No local hooks found", true, true)
  end

  logger("", true, true)

  # Join both results and return result
  result = []
  result.concat(global_extra_hooks)
  result.concat(local_extra_hooks)
  return result
end


def get_executables(directory)
  executables = []
  if File.directory?(directory)
    logger("  - Found folder: #{directory}", true, true)
    Dir.foreach(directory) do |item|
      next if item == '.' or item == '..'
      # Use full relative path
      path = "#{directory}/#{item}"
      # Test if the file is executable
      if File.executable?(path)
        logger("  - Found executable file: #{path} ...", true, false)
        # Remember it, if so
        executables.push(path)
        logger(" [added]", true, true)
      end
    end
  else
    logger("  - Folder not found: #{directory}", true, true)
  end
  return executables
end


def call_extra_hooks(extra_hooks, stdin)
  # Call each exectuble found with the parameters we got
  extra_hooks.each do |extra_hook|
    logger("  - Executing extra hook '#{extra_hook}'")

    IO.popen("#{extra_hook}", "w+") do |pipe|
      begin
        pipe.puts stdin
        pipe.close_write
        logger("#{pipe.read}")
      rescue => e
        logger("Error while executing hook #{extra_hook}", false, true)
        logger("#{e.message}", true, true)
      end
    end
  end
end


###############################
##                           ##
##           MAIN            ##
##                           ##
###############################

STDOUT.sync = true
$debug = false

## Load Gitolite config variables
redmine_vars_hash = load_gitolite_vars

## Set debug mode if needed
$debug = redmine_vars_hash["debugmode"] == "true"

## Let's read the refs passed to us, but also copy stdin
## for potential use with extra hooks.
refs = []
stdin_copy = ""
$<.each do |line|
  r = line.chomp.strip.split
  refs.push( [ r[0].to_s, r[1].to_s, r[2].to_s ].join(",") )
  stdin_copy = (stdin_copy == "" ? "" : $/) + line
end

## Set refs
redmine_vars_hash["refs[]"] = refs

## Fork if needed
if redmine_vars_hash["asyncmode"] == "true"
  pid = fork
  exit unless pid.nil?
  pid = fork
  exit unless pid.nil?

  File.umask 0000

  STDIN.reopen '/dev/null'
  STDOUT.reopen '/dev/null', 'a'
  STDERR.reopen STDOUT
end

## Do the job!
logger("", false, true)
logger("Notifying Redmine project '#{redmine_vars_hash['projectid']}' about changes to this repo...", false, true)

## Call Redmine
success = run_http_query(redmine_vars_hash["redmineurl"], redmine_vars_hash)

if !success
  logger("Error contacting Redmine about changes to this repo.", false, true)
end

logger("", false, true)

## Execute extra hooks
extra_hooks = get_extra_hooks
if extra_hooks.length > 0
  logger("Calling additional post-receive hooks...", false, true)
  call_extra_hooks(extra_hooks, stdin_copy)
end

exit 0
