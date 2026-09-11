# lib/capistrano/tasks/diag.rake
# Read-only post-deploy verification tasks (mirrors the pattern used in
# SmartcheqWebsiteRor7's lib/capistrano/tasks/revision.rake).

namespace :diag1 do
  desc "Read-only: confirm the Registry Lookup / Provenance Timeline doc update deployed to app/views/docs/validation_desk.html.erb"
  task :verify_validation_desk_doc_update do
    on roles(:app) do
      within current_path do
        info "-- REVISION --"
        capture("cat #{current_path}/REVISION 2>/dev/null || echo NO_REVISION_FILE").each_line { |l| info l.rstrip }
        info "-- new callout present --"
        capture("grep -n 'Provenance Timeline now shows real mint' #{current_path}/app/views/docs/validation_desk.html.erb || echo NOT_FOUND").each_line { |l| info l.rstrip }
        info "-- button row updated --"
        capture("grep -n 'resolves the note.s mint issuer' #{current_path}/app/views/docs/validation_desk.html.erb || echo NOT_FOUND").each_line { |l| info l.rstrip }
      end
    end
  end
end
