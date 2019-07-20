module BootstrapKit::AjaxHelper
  def render_flash_messages_as_js(target = '#flash-messages', opts = {})
    js_render(target, render_flash_messages, opts).html_safe
  end

  def js_render_template(target, template, opts = {})
    locals = opts.delete(:locals) { {} }
    content = render(template: template, locals: locals)
    js_render(target, content, opts)
  end

  def js_render_partial(target, partial, opts = {})
    locals = opts.delete(:locals) { {} }
    content = render(partial: partial, locals: locals)
    js_render(target, content, opts)
  end

  def js_render(target, content, opts = {})
    method = opts.delete(:method) { :inject }
    "$('#{target}').#{js_rendering_method(method)}(\"#{escape_javascript(content)}\");\n".html_safe
  end

  def js_rendering_method(method)
    case method
    when :append
      'append'
    when :inject
      'html'
    when :replace
      'replaceWith'
    end
  end
end
