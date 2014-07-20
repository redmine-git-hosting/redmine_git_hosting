---
layout: default
title: JBox Web
---

### {{ page.title }}
***


#### Who we are?

A french Web Agency, based in Marseille, France.

Visit our website : [http://www.jbox-web.com](http://www.jbox-web.com).

<div class="container">
  {% for member in site.github.organization_members %}
    {% if member.login == 'n-rodriguez' %}
      <div class="octocard">
        <script data-name="{{ member.login }}" src="{{ site.baseurl }}/javascripts/octocard.js"></script>
      </div>
    {% endif %}
  {% endfor %}
</div>
