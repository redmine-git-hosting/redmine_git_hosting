---
id: footer
search: exclude
---

<div class="col-sm-1">
  <a href="{{ site.data.project.author.url }}">
    <img class="thumbnail img-responsive" src="{{ site.baseurl }}/images/jbox_logo.jpg" alt="JBox Web" />
  </a>
</div>

<div class="col-sm-10 centered">
  &copy; {{ site.data.project.release.year }} <a href="{{ site.data.project.author.url }}">{{ site.data.project.author.name }}</a>.
  Licensed under the <a href="{{ site.data.project.license.url }}">{{ site.data.project.license.name }} License</a>.
  <br>Sponsored by <a href="{{ site.data.project.author.url }}">{{ site.data.project.author.name }}</a>.
  <br>
  <span class="container centered">
    <ul class="list-inline">
      <li>
        <a href="https://codeclimate.com/github/{{ site.data.project.github_user }}/{{ site.data.project.github_repository }}"><img src="https://codeclimate.com/github/{{ site.data.project.github_user }}/{{ site.data.project.github_repository }}.png" alt="Code Climate" /></a>
      </li>

      <li>
        <a href="https://travis-ci.org/{{ site.data.project.github_user }}/{{ site.data.project.github_repository }}"><img src="https://travis-ci.org/{{ site.data.project.github_user }}/{{ site.data.project.github_repository }}.svg?branch=devel" alt="Build Status" /></a>
      </li>

      <li>
        <a href="https://gemnasium.com/{{ site.data.project.github_user }}/{{ site.data.project.github_repository }}"><img src="https://gemnasium.com/{{ site.data.project.github_user }}/{{ site.data.project.github_repository }}.svg" alt="Dependency Status" /></a>
      </li>
    </ul>
  </span>
</div>

<div class="col-sm-1">
  <p class="text-right"><a href="#top">&#x25B2;</a></p>
</div>
