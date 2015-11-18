---
title: Download
permalink: /download/
layout: homepage
---

<div class="row">
  <div class="col-lg-6">
    <h2>Stable version</h2>
    <p>This is the latest stable version : <span class="label label-success">{{ site.data.project.release.version }}</span></p>
    <p>Once downloaded, follow the <a href="{{ site.baseurl }}/get_started/">Step by Step installation guide</a> or the
      <a href="{{ site.baseurl }}/how-to/migrate/">Step by Step migration guide</a>.</p>

    <ul class="release-downloads">
      <li>
        <a class="btn btn-primary" rel="nofollow" href="https://github.com/jbox-web/redmine_git_hosting/archive/{{ site.data.project.release.version }}.zip">
        <span class="glyphicon glyphicon-download-alt"></span>
        Download (zip)
        </a>
      </li>
        <li>
        <a class="btn btn-primary" rel="nofollow" href="https://github.com/jbox-web/redmine_git_hosting/archive/{{ site.data.project.release.version }}.tar.gz">
        <span class="glyphicon glyphicon-download-alt"></span>
        Download (tar.gz)
        </a>
      </li>
    </ul>
  </div>
  <div class="col-lg-6">
    <h2>Requirements</h2>

    <ul class="list-unstyled">
      <li><strong>Ruby :</strong> works with Ruby <strong>2.x</strong></li>
      <li><strong>Git :</strong> works with Git from <strong>1.7.x</strong> to <strong>2.x</strong></li>
      <li><strong>Redmine :</strong> works with Redmine <strong>2.x</strong> and <strong>3.x</strong> (<a href="https://travis-ci.org/jbox-web/redmine_git_hosting">Tested</a> with latest stable : <strong>{{ site.data.project.release.latest_redmine_version }}</strong>)</li>
      <li><strong>Gitolite :</strong> works with Gitolite <strong>2.x</strong> and <strong>3.x</strong> (<a href="https://travis-ci.org/jbox-web/redmine_git_hosting">Tested</a> with latest stable : <strong>v3.6.2-12-g1c61d57</strong>)</li>
      <li><strong>Database :</strong> works with MySQL and Postgres</li>
    </ul>
  </div>
</div>

<div class="row">
  <div class="col-lg-12">

    <h3>Known issues</h3>
    <hr/>

{{ site.data.callouts.alertwarning }}
  There is a known issue with Redmine **2.6.3** and Redmine **3.0.1**. **Don't install these versions!** [Take a look here for more infos](https://github.com/jbox-web/redmine_git_hosting/issues/387).
{{ site.data.callouts.end }}

    <h3>Announcements</h3>
    <hr/>

{{ site.data.callouts.alertwarning }}
  Support for Gitolite v2 will be drop in next stable branch ! (so actually **2.x**, the current stable branch is **1.x**). You're **strongly encouraged** to migrate to Gitolite v3.
{{ site.data.callouts.end }}

  </div>
</div>
