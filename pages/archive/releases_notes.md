---
title: Releases notes archives
permalink: /archives/releases-notes/
layout: page
---

<ul class="list-group">
  {% for post in site.categories['releases-notes'] %}
    <li class="list-group-item" style="margin: -1px;">
      <h4><a href="{{ site.baseurl }}{{ post.url }}">{{ post.title }}</a></h4>
      {% if post.status == 'beta' %}
        <p><strong>Release date :</strong> Pending</p>
      {% else %}
        <p><strong>Release date :</strong> {{ post.date | date: "%-d %B %Y" }}</p>
      {% endif %}
      <p>
        <strong>Status :</strong>
        {% if post.status == 'latest stable' %}
          <span class="label label-success">{{ post.status }}</span>
        {% elsif post.status == 'old stable' %}
          <span class="label label-warning">{{ post.status }}</span>
        {% elsif post.status == 'obsolete' %}
          <span class="label label-default">{{ post.status }}</span>
        {% elsif post.status == 'beta' %}
          <span class="label label-danger">{{ post.status }}</span>
        {% elsif post.status == 'next stable' %}
          <span class="label label-success">{{ post.status }}</span>
        {% else %}
          <span class="label label-primary">{{ post.status }}</span>
        {% endif %}
      </p>

      <p><strong>Download :</strong>
        {% if post.status == 'next stable' || post.status == 'beta' %}
          Not released yet, come back later!
        {% else %}
          <a class="btn btn-sm btn-primary" rel="nofollow" href="{{ post.download_zip }}">
          <span class="glyphicon glyphicon-compressed"></span>
          Source code (zip)
          </a>

          <a class="btn btn-sm btn-primary" rel="nofollow" href="{{ post.download_tar }}">
          <span class="glyphicon glyphicon-compressed"></span>
          Source code (tar.gz)
          </a>
        {% endif %}
      </p>

      <p><strong>Changelog :</strong></p>

      {{ post.content }}
    </li>
  {% endfor %}
</ul>
