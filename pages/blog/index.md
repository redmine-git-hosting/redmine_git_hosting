---
title: Blog
permalink: /blog/
layout: homepage
---

<h1>{{ page.title }} <a href="{{ site.baseurl }}/news/feed.atom"><i class="fa fa-rss"></i>&nbsp;</a></h1>

***


<ul class="list-group">
  {% for post in site.categories['news'] limit:4 %}
    <li class="list-group-item">
      <p>
        <strong>{{ post.date | date: "%-d %B %Y" }} :</strong>
        <a href="{{ site.baseurl }}{{ post.url }}">{{ post.title }}</a>
        {% if site.github.url %}
          {% assign base = site.github.url %}
        {% else %}
          {% assign base = 'https://jbox-web.github.io/redmine_git_hosting' %}
        {% endif %}
        <a class="twitter-share-button" data-count="none" data-via="TchoumTux" data-lang="en" data-text="{{ post.title }}" data-url="{{ base }}{{ post.url }}"
          href="https://twitter.com/share"><i class="fa fa-twitter"></i>&nbsp;Tweet me!</a>
      </p>
      {{ post.excerpt }}
    </li>
  {% endfor %}
</ul>

<div class="home-read-more">
  <a href="{{ "/archives/posts" | prepend:site.baseurl }}" class="btn btn-primary btn-lg">View all {{ site.categories['news'] | size }} posts →</a>
</div>
