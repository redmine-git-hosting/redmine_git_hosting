module RepositoryMirrorsHelper
  # Mirror Mode
  def mirror_mode(mirror)
    [l(:label_mirror_full_mirror),
     l(:label_mirror_forced_update),
     l(:label_mirror_fast_forward)][mirror.push_mode]
  end

  # Refspec for mirrors
  def refspec(mirror, max_refspec = 0)
    if mirror.mirror_mode?
      l :all_references
    else
      result = []
      result << tag.li(l(:all_branches)) if mirror.include_all_branches
      result << tag.li(l(:all_tags)) if mirror.include_all_tags
      result << tag.li(mirror.explicit_refspec) if max_refspec.zero? || ((1..max_refspec) === mirror.explicit_refspec.length)
      result << tag.li(l(:explicit)) if max_refspec.positive? && (mirror.explicit_refspec.length > max_refspec)

      tag.ul(safe_join(result), class: 'list-unstyled') if result.any?
    end
  end

  def mirrors_options
    [
      [l(:label_mirror_full_mirror), 0],
      [l(:label_mirror_forced_update), 1],
      [l(:label_mirror_fast_forward), 2]
    ]
  end

  def render_push_state(mirror, error)
    if error
      status = l(:label_mirror_push_fail)
      status_css = 'important'
    else
      status = l(:label_mirror_push_sucess)
      status_css = 'success'
    end

    l(:label_mirror_push_info_html, mirror_url: mirror.url, status: status, status_css: status_css).html_safe
  end
end
