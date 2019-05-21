FactoryBot.define do
  factory :role do
    name { 'Manager' }
    builtin { 0 }
    issues_visibility { 'all' }
    position { 1 }
    permissions do
      %i[add_project edit_project close_project select_project_modules manage_members
         manage_versions manage_categories view_issues add_issues edit_issues manage_issue_relations
         manage_subtasks add_issue_notes move_issues delete_issues view_issue_watchers add_issue_watchers
         set_issues_private set_notes_private view_private_notes delete_issue_watchers
         manage_public_queries save_queries view_gantt view_calendar log_time view_time_entries
         edit_time_entries delete_time_entries manage_news comment_news view_documents
         add_documents edit_documents delete_documents view_wiki_pages export_wiki_pages
         view_wiki_edits edit_wiki_pages delete_wiki_pages_attachments protect_wiki_pages
         delete_wiki_pages rename_wiki_pages add_messages edit_messages delete_messages
         manage_boards view_files manage_files browse_repository manage_repository view_changesets
         manage_related_issues manage_project_activities create_gitolite_ssh_key commit_access]
    end
  end
end
