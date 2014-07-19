---
layout: default
title: Releases Notes
---

### {{ page.title }}
***

{% for post in site.categories['release-notes'] %}
  <h4><a href="{{ post.url }}">{{ post.title }}</a></h4>
  <p><strong>Date :</strong> {{ post.date | date: "%-d %B %Y" }}</p>
  <p><strong>Status :</strong> {{ post.status }}</p>
  <p><strong>Download :</strong> <a href="{{ post.download }}">here</a></p>
  <p><strong>Changelog :</strong></p>
  {{ post.excerpt }}
  <hr>
{% endfor %}

<div id="toc">
</div>
