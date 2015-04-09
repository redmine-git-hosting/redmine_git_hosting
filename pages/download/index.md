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
    <h2>Development version</h2>
    <p>This is the current development version.</p>
    <p>Once downloaded, follow the <a href="{{ site.baseurl }}/guide/development/">Development guide</a>.</p>

    <ul class="release-downloads">
      <li>
        <a class="btn btn-primary" rel="nofollow" href="https://github.com/jbox-web/redmine_git_hosting/archive/devel.zip">
        <span class="glyphicon glyphicon-download-alt"></span>
        Download (zip)
        </a>
      </li>
        <li>
        <a class="btn btn-primary" rel="nofollow" href="https://github.com/jbox-web/redmine_git_hosting/archive/devel.tar.gz">
        <span class="glyphicon glyphicon-download-alt"></span>
        Download (tar.gz)
        </a>
      </li>
    </ul>
  </div>
</div>

<div class="row">
  <div class="col-lg-12">
    <h3>Requirements</h3>
    <hr/>
    <ul>
      <li><strong>Redmine :</strong> works with Redmine <strong>2.x</strong> and <strong>3.x</strong> (<a href="https://travis-ci.org/jbox-web/redmine_git_hosting">Tested</a> with latest stable : <strong>3.0.1</strong>)</li>
      <li><strong>Ruby :</strong> works with Ruby 2.0 and 2.1</li>
      <li><strong>Git :</strong> works with Git from 1.7.x to 2.x</li>
      <li><strong>Gitolite :</strong> works with Gitolite 2.x and 3.x (<a href="https://travis-ci.org/jbox-web/redmine_git_hosting">Tested</a> with latest stable : <strong>v3.6.2-12-g1c61d57</strong>)</li>
      <li><strong>Database :</strong> works with MySQL and Postgres</li>
    </ul>

    <h3>Known issues</h3>
    <hr/>

{{ site.data.callouts.alertwarning }}
  There is a known issue with Redmine **2.6.3** and Redmine **3.0.1**. **Don't install these versions!** [Take a look here for more infos](https://github.com/jbox-web/redmine_git_hosting/issues/387).
{{ site.data.callouts.end }}

{{ site.data.callouts.alertwarning }}
  There is a known issue with Gitolite 3 and SmartHTTP access. [Take a look here to fix it]({{ site.baseurl }}/troubleshooting#hook-errors-while-pushing-over-https).
{{ site.data.callouts.end }}

    <h3>Announcements</h3>
    <hr/>

{{ site.data.callouts.alertwarning }}
  Support for Ruby 1.9 has been dropped ! See [here](https://www.ruby-lang.org/en/news/2014/01/10/ruby-1-9-3-will-end-on-2015/) for more informations.
{{ site.data.callouts.end }}

{{ site.data.callouts.alertwarning }}
  Support for Gitolite v2 will be drop in next stable branch ! (so actually **1.1.x**, the current stable branch is **1.0.x**). You're **strongly encouraged** to migrate to Gitolite v3.
{{ site.data.callouts.end }}

  </div>
</div>
