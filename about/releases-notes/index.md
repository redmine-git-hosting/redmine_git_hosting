---
layout: default
title: Releases Notes
---

<h3>{{ page.title }} <a href="{{ site.baseurl }}/about/releases-notes/feed.atom"><i class="fa fa-rss"></i>&nbsp;</a></h3>

***

<ul class="list-group">
  {% for post in site.categories['release-notes'] %}
    <li class="list-group-item">
      <h4><a href="{{ site.baseurl }}{{ post.url }}">{{ post.title }}</a></h4>
      <p><strong>Date :</strong> {{ post.date | date: "%-d %B %Y" }}</p>
      <p>
        <strong>Status :</strong>
        {% if post.status == 'latest stable' %}
          <span class="label label-success">{{ post.status }}</span>
        {% elsif post.status == 'old stable' %}
          <span class="label label-warning">{{ post.status }}</span>
        {% elsif post.status == 'obsolete' %}
          <span class="label label-default">{{ post.status }}</span>
        {% else %}
          <span class="label label-primary">{{ post.status }}</span>
        {% endif %}
      </p>
      <p><strong>Download :</strong></p>
      <ul class="release-downloads">
        <li>
          <a class="btn btn-primary" rel="nofollow" href="{{ post.download_zip }}">
          <span class="glyphicon glyphicon-compressed"></span>
          Source code (zip)
          </a>
        </li>
          <li>
          <a class="btn btn-primary" rel="nofollow" href="{{ post.download_tar }}">
          <span class="glyphicon glyphicon-compressed"></span>
          Source code (tar.gz)
          </a>
        </li>
      </ul>
      <p><strong>Changelog :</strong></p>
      {{ post.excerpt }}
    </li>
  {% endfor %}
</ul>

<div id="toc">
</div>
