var all_git_url_ids = ["git_url_ssh", "git_url_http", "git_url_https", "git_url_git"];

function updateGitUrl(element) {
  if (element != null) {
    var selected_id = element.id;
  } else {
    return false;
  }

  document.getElementById("git_url_text").value = urls[selected_id][0];
  document.getElementById("git_url_permissions").innerHTML = urls[selected_id][1] ? "Read+Write" : "Read-Only";

  var git_url_access = document.getElementsByClassName("git_url_access");
  if (git_url_access){
    for (var i = 0; i < git_url_access.length; i++) {
      git_url_access[i].innerHTML = urls[selected_id][0];
    }
  }

  var setup_box = document.getElementById('repository_setup');
  if (setup_box){
    if (selected_id == 'git_url_git') {
      setup_box.style.display = "none";
    } else {
      setup_box.style.display = "";
    }
  }

  for(var i = 0; i < all_git_url_ids.length; i++) {
    var test_id = all_git_url_ids[i];
    var test_el = document.getElementById(test_id);
    if (test_el != null) {
      test_el.className = test_id == selected_id ? "selected" : "";
    }
  }
}

function setGitUrl() {
  // highlight input text on click
  var git_input = document.getElementById('git_url_text');
  if (git_input) {
    git_input.setAttribute("onclick", "this.select()");
  }

  var i = 0;
  var first_element = null;
  for(i = 0; i < all_git_url_ids.length; i++) {
    var element = document.getElementById(all_git_url_ids[i]);
    if(element != null) {
      first_element = first_element == null ? element : first_element;
      element.setAttribute("onclick", "updateGitUrl(this)");
    }
  }
  updateGitUrl(first_element);
}
