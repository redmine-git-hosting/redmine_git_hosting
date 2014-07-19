---
layout: default
title: News
group: navigation
weight: 1
---

### News
***

<ul>
  {% for post in site.categories['news'] %}
    <li>
      <p>
        {{ post.date | date: "%-d %B %Y" }} :
        <a href="{{ post.url }}">{{ post.title }}</a>
      </p>
      {{ post.excerpt }}
      <hr>
    </li>
  {% endfor %}
</ul>
