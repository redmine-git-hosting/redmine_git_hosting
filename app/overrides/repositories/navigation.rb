# frozen_string_literal: true

Deface::Override.new virtual_path: 'repositories/_navigation',
                     name: 'show-repositories-hook-navigation',
                     insert_before: 'erb[loud]:contains("label_statistics")',
                     original: '88f120e99075ba3246901c6e970ca671d7166855',
                     text: '<%= call_hook(:view_repositories_navigation, repository: @repository) %>'

module Repositories
  module Navigation
  end
end
