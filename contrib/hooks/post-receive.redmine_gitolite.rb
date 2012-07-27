#!/usr/bin/env ruby

require 'digest/sha1'
require 'net/http'
require 'net/https'
require 'uri'

STDOUT.sync=true
$debug=false


def log(msg, debug_only=false, with_newline=true)
	if $debug || (!debug_only)
		print msg + (with_newline ? "\n" : "")
	end
end
def get_git_repository_config(varname)
	(%x[git config #{varname} ]).chomp.strip
end
def get_http_params(rgh_vars)
	clear_time   = Time.new.utc.to_i.to_s
	params = { "clear_time" => clear_time, "encoded_time" => Digest::SHA1.hexdigest(clear_time.to_s + rgh_vars["key"]) }
	rgh_vars.each_key do |v|
		if v != "key"
			params[v] = rgh_vars[v]
		end
	end
	params
end

# Need to do this ourselves, because 1.8.7 ruby is broken
def set_form_data(request, params, sep = '&')
	request.body = params.map {|k,v|
		if v.instance_of?(Array)
			v.map {|e| "#{urlencode(k.to_s)}=#{urlencode(e.to_s)}"}.join(sep)
		else
			"#{urlencode(k.to_s)}=#{urlencode(v.to_s)}"
		end
	}.join(sep)

	request.content_type = 'application/x-www-form-urlencoded'
end

def urlencode(str)
	str.gsub(/[^a-zA-Z0-9_\.\-]/n) {|s| sprintf('%%%02x', s[0]) }
end

def run_query(url_str, params, with_https)
	url_str = (with_https ?	 "https://" : "http://" ) + url_str.gsub(/^http[s]*:\/\//, "")
	success = false
	begin
		url  = URI.parse(url_str)
		http = Net::HTTP.new( url.host, url.port )
		http.open_timeout = 20
		http.read_timeout = 180
		if with_https
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		end
		req  = Net::HTTP::Post.new(url.request_uri)
		set_form_data(req,params)
		response = http.request(req) do |response|
			response.read_body do |body_frag|
				success = response.code.to_i == 200 ? true : false
				log(body_frag, false, false)
			end
		end
		#response = http.request(req)
		#puts response.header
	rescue Exception =>e
		#log("HTTP_ERROR:" + e.to_s, true, true)
		success = false
	end
	success
end




rgh_vars = {}
rgh_var_names = [ "hooks.redmine_gitolite.key", "hooks.redmine_gitolite.url", "hooks.redmine_gitolite.projectid", "hooks.redmine_gitolite.debug", "hooks.redmine_gitolite.asynch"]
rgh_var_names.each do |var_name|
	var_val = get_git_repository_config(var_name)
	if var_val.to_s == ""
		log("\n\nRepository does not have \"#{var_name}\" set. Skipping hook.\n\n", false, true)
		exit
	else
		var_name = var_name.gsub(/^.*\./, "")
		rgh_vars[ var_name ] = var_val
	end
end

$debug = rgh_vars["debug"] == "true"


# Let's read the refs passed to us
refs = []
$<.each	 do |line|
	r = line.chomp.strip.split
	refs.push( [ r[0].to_s, r[1].to_s, r[2].to_s ].join(",") )
end
rgh_vars["refs[]"] = refs

if rgh_vars["asynch"] == "true"
	pid = fork
	exit unless pid.nil?
	pid = fork
	exit unless pid.nil?

	File.umask 0000

	STDIN.reopen '/dev/null'
	STDOUT.reopen '/dev/null', 'a'
	STDERR.reopen STDOUT

end

log("\n\n", false, true)
log("Notifying ChiliProject/Redmine project #{rgh_vars['projectid']} about changes to this repo...", true, true)
success = run_query(rgh_vars["url"], get_http_params(rgh_vars), true)
if !success
	success = run_query(rgh_vars["url"], get_http_params(rgh_vars), false)
end
if(!success)
	log("Error contacting ChiliProject/Redmine about changes to this repo.", false, true)
else
	log("Success", true, true)
	log("", true, true)
end
log("\n\n", false, true)

exit
