module RepositoryPostReceiveUrlsHelper

  # Post-receive Mode
  def post_receive_mode(prurl)
    label = []
    if prurl.github_mode?
      label << l(:label_github_post)
      label << "(#{l(:label_split_payloads)})" if prurl.split_payloads?
    else
      label << l(:label_empty_get)
    end
    label.join(' ')
  end

end
