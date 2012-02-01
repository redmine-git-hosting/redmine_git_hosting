var allGitUrlIds = ["git_url_ssh", "git_url_http", "git_url_git"]
function updateGitUrl(el)
{
	guHttpBase = guHttpBase.replace(/\/$/, "")

	var urls=[]
	var gitSHP = /:\d+$/.test(guGitServer)
	urls["git_url_ssh"]  = [(gitSHP ? "ssh://" : "") + guGitUser + "@" + guGitServer + (gitSHP ? "/" : ":") + guSshURL, guUserIsCommitter]
	urls["git_url_http"] = [guHttpProto + "://" + ( (!guProjectIsPublic) || guUserIsCommitter ? encodeURIComponent(guUser) + "@" : "") + guHttpBase + "/" + guHttpURL, guUserIsCommitter]
	urls["git_url_git"]  = ["git://" + guGitServer + "/" + guSshURL, false]
	var allGitUrlIds = ["git_url_ssh", "git_url_http", "git_url_git"]

	var selected_id = el.id
	document.getElementById("git_url_text").value = urls[selected_id][0];
	document.getElementById("git_url_access").innerHTML = urls[selected_id][1] ? "Read+Write" : "Read-Only"

	var i
	for(i=0;i<allGitUrlIds.length; i++)
	{
		var test_id = allGitUrlIds[i];
		var test_el = document.getElementById(test_id)
		if (test_el != null)
		{
			test_el.className = test_id == selected_id ? "selected" : ""
		}
	}
}

function setGitUrlOnload()
{
	// highlight input text on click
	var git_input = document.getElementById("git_url_text");
	if (git_input) {
		git_input.setAttribute("onclick", "this.select()");
	}

	var i
	var firstEl = null
	for(i=0;i<allGitUrlIds.length; i++)
	{
		var el = document.getElementById(allGitUrlIds[i]);
		if(el != null)
		{
			firstEl = firstEl == null ? el : firstEl
			el.setAttribute("onclick", "updateGitUrl(this)")
		}
	}
	updateGitUrl(firstEl)

}

