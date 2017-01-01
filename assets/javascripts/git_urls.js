// GIT URLS
function updateUrl(element) {
  var url = $(element).data('url');
  var target = $(element).data('target');
  var committer = $(element).data('committer');
  $('#git_url_text_' + target).val(url);
  $('#git_url_permissions_' + target).html(committer);
  $(element).parent().find('li').removeClass('selected');
  $(element).addClass('selected');
}

function setGitUrls(elements) {
  $(elements).each(function(index, element){
    $(element).on('click', function(){
      updateUrl($(this));
    });
  });
}

function setFirstGitUrl(elements) {
  $(elements).each(function(index, element){
    var first_url = $(element).children().first();
    updateUrl(first_url);
  });
}

// GIT INSTRUCTIONS
function updateInstructionUrl(element) {
  var url = $(element).data('url');
  var committer = $(element).data('committer');
  $('.git_url_access').html(url);
  if (committer == 'RW') {
    $('#repository_setup').show();
  } else {
    $('#repository_setup').hide();
  }
}

function setGitUrlsInstructions(elements) {
  $(elements).each(function(index, element){
    if (index == 0){
      updateInstructionUrl(element);
    };
    $(element).on('click', function(){
      updateInstructionUrl($(this));
    });
  });
}
