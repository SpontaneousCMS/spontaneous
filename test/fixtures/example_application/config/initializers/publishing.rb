
Site.output_store(:File, dir: Site.revision_root)

Site.publish do
  run :create_revision_directory
  run :render_revision
  run :generate_search_indexes
  run :copy_static_files
  run :generate_rackup_file
  run :activate_revision
  run :write_revision_file
  run :archive_old_revisions
end
