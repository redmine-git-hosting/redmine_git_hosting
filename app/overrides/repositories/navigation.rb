Deface::Override.new virtual_path: 'repositories/_navigation',
                     name: 'show-repositories-hook-bottom',
                     insert_before: 'erb[loud]:contains("label_statistics")',
                     #original: 'f302d110cd10675a0a952f5f3e1ecfe57ebd38be',
                     text: '<%= call_hook(:view_repositories_navigation, repository: @repository) %>'
