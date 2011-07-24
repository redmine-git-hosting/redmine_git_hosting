#!/usr/bin/env python

import os
import sys
import fileinput
import subprocess
import urllib
import urllib2

def log(msg, newline=True):
	sys.stderr.write("%s%s" % (msg, (newline and "\n" or "")))
	sys.stderr.flush()

gl_repo = os.environ.get('GL_REPO', None)
if not gl_repo:
	log("GL_REPO is not defined, skipping hook...")
	sys.exit(0)

def get_git_repository_config(varname, boolean=False):
	args = ["git", "config"]
	if boolean:
		args.append("--bool")
	args.append(varname)
	run = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	run.wait()
	ret = run.stdout.read()
	err = run.stderr.read()
	if err:
		log("Error while getting %r: %s" % (varname, err.strip()))
	if boolean:
		return ret.strip()=="true"
	return ret.strip()

debug = get_git_repository_config("hooks.redmine_gitolite.debug", boolean=True)

key = get_git_repository_config("hooks.redmine_gitolite.key")
if not key:
	log("Repository %s does not have \"hooks.redmine_gitolite.key\" set. Skipping..." % gl_repo)
	sys.exit(0)

server = get_git_repository_config("hooks.redmine_gitolite.server")
if not server:
	log("Repository %s does not have \"hooks.redmine_gitolite.key\" set. Skipping..." % gl_repo)
	sys.exit(0)

project_id = get_git_repository_config("hooks.redmine_gitolite.projectid")
if not project_id:
	log("Repository %s does not have \"hooks.redmine_gitolite.key\" set. Skipping..." % gl_repo)
	sys.exit(0)

## Let's read the refs passed to us
#refs = []
#for line in fileinput.input():
#	old, new, refname = [item.strip() for item in line.split()]
#	refs.append(",".join([old, new, refname]))
#
#log("Refs")
#log(refs)
#log("")
#log(urllib.urlencode({
#		"key": key,
#		"project_id": project_id,
#		"refs": refs
#	}))
#log("")

params = [("key", key), ("project_id", project_id)]
# Let's read the refs passed to us
for line in fileinput.input():
	old, new, refname = [item.strip() for item in line.split()]
	params.append(("refs[]", ",".join([old, new, refname])))

log("\nNotifying ChiliProject/Redmine (%s) about changes to this repo (%s => %s)\n" % (server, gl_repo, project_id))
log("Hitting the ChiliProject/Redmine Gitolite hook")
log("Response: ", False)

req = urllib2.urlopen("http://%s/sys/hooks/post-receive " % (server), urllib.urlencode(params))
log(req.read().strip())

log("Complete")
sys.exit(0)
