---
layout: default
title: Download
group: navigation
weight: 2
---

<div class="row">
  <div class="col-lg-6">
    <h2>Stable version</h2>
    <p>This is the latest stable version : <span class="label label-success">{{ site.data.project.release.version }}</span></p>
    <p>Once downloaded, follow the <a href="{{ site.baseurl }}/howtos/install/#step-by-step-installation">Step by Step installation guide</a> or the
      <a href="{{ site.baseurl }}/howtos/migrate/">Step by Step migration guide</a>.</p>

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
  <div class="col-lg-12">
    <h2>Requirements</h2>
    <ul>
      <li><strong>Redmine :</strong> This plugin only works with Redmine <strong>2.x</strong> (<a href="https://travis-ci.org/jbox-web/redmine_git_hosting">Tested</a> with latest stable : <strong>2.6.1</strong>)</li>
      <li><strong>Ruby :</strong> works with Ruby 1.9.3, 2.0 and 2.1</li>
      <li><strong>Git :</strong> need at least Git <strong>1.8.5</strong> (won't work with older versions of Git)</li>
      <li><strong>Gitolite :</strong> works with Gitolite 2.x and 3.x (<a href="https://travis-ci.org/jbox-web/redmine_git_hosting">Tested</a> with latest stable : <strong>v3.6.2-12-g1c61d57</strong>)</li>
      <li><strong>Database :</strong> works with MySQL and Postgres</li>
    </ul>
    <div class="alert alert-warning" role="alert">
      <p>There is a known issue with Gitolite 3 and SmartHTTP access. <a href="{{ site.baseurl }}/configuration/troubleshooting#hook-errors-while-pushing-over-https">Take a look here to fix it.</a></p>
    </div>
    <div class="alert alert-warning" role="alert">
      <p>Support for Ruby 1.9 will soon be dropped ! See <a href="https://www.ruby-lang.org/en/news/2014/01/10/ruby-1-9-3-will-end-on-2015/">here</a> for more informations.</p>

    </div>
  </div>
</div>
