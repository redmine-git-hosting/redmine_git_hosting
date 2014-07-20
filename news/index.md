---
layout: default
title: News
group: navigation
weight: 1
---

### {{ page.title }}
***

<ul class="list-group">
  {% for post in site.categories['news'] %}
    <li class="list-group-item">
      <p>
        <strong>{{ post.date | date: "%-d %B %Y" }} :</strong>
        <a href="{{ site.baseurl }}{{ post.url }}">{{ post.title }}</a>
      </p>
      {{ post.excerpt }}
    </li>
  {% endfor %}
</ul>
