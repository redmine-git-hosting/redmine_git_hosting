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

    <ul>
      <li>Ruby: 2.5+</li>
      <li>Git: 2.0+</li>
      <li>Redmine: 4.1+</li>
      <li>Gitolite: 3.0+</li>
      <li>Database: MySQL or Postgres</li>
    </ul>
  </div>
</div>
