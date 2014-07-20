---
layout: default
title: Releases Notes
---

### {{ page.title }}
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
        {% else %}
          <span class="label label-primary">{{ post.status }}</span>
        {% endif %}
        </p>
      <p><strong>Download :</strong> <a href="{{ post.download }}">here</a></p>
      <p><strong>Changelog :</strong></p>
      {{ post.excerpt }}
    </li>
  {% endfor %}
</ul>

<div id="toc">
</div>
