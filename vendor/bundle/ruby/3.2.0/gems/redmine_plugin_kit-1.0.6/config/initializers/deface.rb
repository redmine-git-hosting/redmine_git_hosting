# frozen_string_literal: true

Rails.application.paths['app/overrides'] ||= []
Rails.root.glob('plugins/*/app/overrides').each do |path|
  Rails.application.paths['app/overrides'] << path unless Rails.application.paths['app/overrides'].include? path
end

Rails.root.glob('plugins/*/app/overrides/**/*.deface').each do |path|
  Deface::DSL::Loader.load File.expand_path(path, __FILE__)
end
