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

hook_url = get_git_repository_config("hooks.redmine_gitolite.url")
if not hook_url:
	log("Repository %s does not have \"hooks.redmine_gitolite.url\" set. Skipping..." % gl_repo)
	sys.exit(0)

project_id = get_git_repository_config("hooks.redmine_gitolite.projectid")
if not project_id:
	log("Repository %s does not have \"hooks.redmine_gitolite.projectid\" set. Skipping..." % gl_repo)
	sys.exit(0)

params = [("key", key), ("project_id", project_id)]
# Let's read the refs passed to us
for line in fileinput.input():
	old, new, refname = [item.strip() for item in line.split()]
	params.append(("refs[]", ",".join([old, new, refname])))

log("Notifying ChiliProject/Redmine project %s about changes to this repo %s.git ..." % (project_id, gl_repo))
req = urllib2.urlopen("%s/post-receive" % hook_url, urllib.urlencode(params))
log("Response: %s" % req.read().strip())
sys.exit(0)
