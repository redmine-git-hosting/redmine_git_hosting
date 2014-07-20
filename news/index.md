---
layout: default
title: News
group: navigation
weight: 1
---

<h3>{{ page.title }} <a href="{{ site.baseurl }}/news/feed.atom"><i class="fa fa-rss"></i>&nbsp;</a></h3>

***

<ul class="list-group">
  {% for post in site.categories['news'] %}
    <li class="list-group-item">
      <p>
        <strong>{{ post.date | date: "%-d %B %Y" }} :</strong>
        <a href="{{ site.baseurl }}{{ post.url }}">{{ post.title }}</a> -
        {% if site.github.url %}
          {% assign base = site.github.url %}
        {% else %}
          {% assign base = 'https://jbox-web.github.io/redmine_git_hosting' %}
        {% endif %}
        <a class="twitter-share-button" data-via="TchoumTux" data-lang="en" data-text="{{ post.title }}" data-url="{{ base }}{{ post.url }}"
          href="https://twitter.com/share"><i class="fa fa-twitter"></i>&nbsp;Tweet me!</a>
      </p>
      {{ post.excerpt }}
    </li>
  {% endfor %}
</ul>
