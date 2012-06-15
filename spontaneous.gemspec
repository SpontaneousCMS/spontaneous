## This is the rakegem gemspec template. Make sure you read and understand
## all of the comments. Some sections require modification, and others can
## be deleted if you don't need them. Once you understand the contents of
## this file, feel free to delete any comments that begin with two hash marks.
## You can find comprehensive Gem::Specification documentation, at
## http://docs.rubygems.org/read/chapter/20
Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'
  s.required_ruby_version = ">= 1.9.2"

  ## Leave these as is they will be modified for you by the rake gemspec task.
  ## If your rubyforge_project name is different, then edit it and comment out
  ## the sub! line in the Rakefile
  s.name              = 'spontaneous'
  s.version           = '0.2.0.alpha2'
  s.date              = '2012-06-04'
  s.rubyforge_project = 'spontaneous'

  ## Make sure your summary is short. The description may be as long
  ## as you like.
  s.summary     = "Spontaneous is a next-generation Ruby CMS"
  s.description = "Spontaneous is a next-generation Ruby CMS"

  ## List the primary authors. If there are a bunch of authors, it's probably
  ## better to set the email to an email list or something. If you don't have
  ## a custom homepage, consider using your GitHub URL or the like.
  s.authors  = ["Garry Hill"]
  s.email    = 'garry@magnetised.net'
  s.homepage = 'http://spontaneouscms.org'

  ## This gets added to the $LOAD_PATH so that 'lib/NAME.rb' can be required as
  ## require 'NAME.rb' or'/lib/NAME/file.rb' can be as require 'NAME/file.rb'
  s.require_paths = %w[lib]

  # ## This sections is only necessary if you have C extensions.
  # s.require_paths << 'ext'
  # s.extensions = %w[ext/extconf.rb]

  ## If your gem includes any executables, list them here.
  s.executables = ["spot"]

  ## Specify any RDoc options here. You'll want to add your README and
  ## LICENSE files to the extra_rdoc_files list.
  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[README LICENSE]

  ## List your runtime dependencies here. Runtime dependencies are those
  ## that are needed for an end user to actually USE your code.
  s.add_dependency('activesupport',   ["~> 3.2.0"])
  s.add_dependency('base58',          ["~> 0.1.0"])
  s.add_dependency('bundler',         ["> 1.0.15"])
  s.add_dependency('coffee-script',   ["~> 2.2.0"])
  s.add_dependency('erubis',          ["~> 2.6"])
  s.add_dependency('fog',             ["~> 1.1.1"])
  s.add_dependency('foreman',         ["~> 0.22.0"])
  s.add_dependency('kramdown',        ["~> 0.13.3"])
  s.add_dependency('launchy',         ["~> 0.4.0"])
  s.add_dependency('mini_magick',     ["~> 3.3"])
  s.add_dependency('nokogiri',        ["~> 1.5.0"])
  s.add_dependency('public_suffix',   ["~> 1.0"])
  s.add_dependency('rack',            ["~> 1.4.1"])
  s.add_dependency('rack-fiber_pool', ["~> 0.9.2"])
  s.add_dependency('rake',            ["~> 0.9.2"])
  s.add_dependency('rdoc',            ["~> 3.9.4"])
  s.add_dependency('sass',            ["~> 3.1.4"])
  s.add_dependency('sequel',          ["= 3.36.1"])
  s.add_dependency('shine',           ["~> 0.6"])
  s.add_dependency('simultaneous',    ["~> 0.4"])
  s.add_dependency('sinatra',         ["= 1.3.2"])
  s.add_dependency('sinatra-contrib', ["~> 1.3.1"])
  s.add_dependency('stringex',        ["= 1.3"])
  s.add_dependency('therubyracer',    ['~> 0.9.10'])
  s.add_dependency('thin',            ["~> 1.2"])
  s.add_dependency('thor',            ["~> 0.14.6"])
  s.add_dependency('yajl-ruby',       ["~> 1.1"])

  ## List your development dependencies here. Development dependencies are
  ## those that are only needed during development
  s.add_development_dependency('minitest', ["~> 2.1.0"])
  s.add_development_dependency('mysql2', ["~> 0.3.11"])
  s.add_development_dependency('pg', ["~> 0.13.2"])
  s.add_development_dependency('jeweler', ["~> 1.5"])
  s.add_development_dependency('jnunemaker-matchy', ["~> 0.4"])
  s.add_development_dependency('shoulda', ["~> 2.11.3"])
  s.add_development_dependency('timecop', ["~> 0.3"])
  s.add_development_dependency('mocha', ["~> 0.9"])
  s.add_development_dependency('rack-test', ["~> 0.5"])
  s.add_development_dependency('leftright', ["~> 0.9"])
  s.add_development_dependency('stackdeck', ["~> 0.2"])

  ## Leave this section as-is. It will be automatically generated from the
  ## contents of your Git repository via the gemspec task. DO NOT REMOVE
  ## THE MANIFEST COMMENTS, they are used as delimiters by the task.
  # = MANIFEST =
  s.files = %w[
    Gemfile
    LICENSE
    README
    Rakefile
    Readme.markdown
    application/css/add_alias_dialogue.scss
    application/css/definitions.scss
    application/css/developer.scss
    application/css/dialogue.scss
    application/css/editing.scss
    application/css/font.scss
    application/css/login.scss
    application/css/popover.scss
    application/css/schema_error.scss
    application/css/spontaneous.scss
    application/css/unsupported.scss
    application/css/v2.scss
    application/css/variables.scss
    application/js/add_alias_dialogue.js
    application/js/add_home_dialogue.js
    application/js/ajax.js
    application/js/authentication.js
    application/js/box.js
    application/js/box_container.js
    application/js/compatibility.js
    application/js/conflicted_field_dialogue.js
    application/js/content.js
    application/js/content_area.js
    application/js/dialogue.js
    application/js/dom.js
    application/js/edit_panel.js
    application/js/editing.js
    application/js/entry.js
    application/js/event_source.js
    application/js/extensions.js
    application/js/field.js
    application/js/field_preview.js
    application/js/field_types/date_field.js
    application/js/field_types/file_field.js
    application/js/field_types/image_field.js
    application/js/field_types/long_string_field.js
    application/js/field_types/markdown_field.js
    application/js/field_types/select_field.js
    application/js/field_types/string_field.js
    application/js/field_types/webvideo_field.js
    application/js/image.js
    application/js/init.js
    application/js/load.js
    application/js/location.js
    application/js/login.js
    application/js/metadata.js
    application/js/page.js
    application/js/page_browser.js
    application/js/page_entry.js
    application/js/panel/root_menu.js
    application/js/popover.js
    application/js/popover_view.js
    application/js/preview.js
    application/js/progress.js
    application/js/properties.js
    application/js/publish.js
    application/js/require.js
    application/js/services.js
    application/js/sharded_upload.js
    application/js/side_bar.js
    application/js/spontaneous.js
    application/js/state.js
    application/js/status_bar.js
    application/js/top_bar.js
    application/js/types.js
    application/js/upload.js
    application/js/upload_manager.js
    application/js/user.js
    application/js/vendor/JS.Class-2.1.5/CHANGELOG
    application/js/vendor/JS.Class-2.1.5/MIT-LICENSE
    application/js/vendor/JS.Class-2.1.5/README
    application/js/vendor/JS.Class-2.1.5/min/command.js
    application/js/vendor/JS.Class-2.1.5/min/comparable.js
    application/js/vendor/JS.Class-2.1.5/min/constant_scope.js
    application/js/vendor/JS.Class-2.1.5/min/core.js
    application/js/vendor/JS.Class-2.1.5/min/decorator.js
    application/js/vendor/JS.Class-2.1.5/min/enumerable.js
    application/js/vendor/JS.Class-2.1.5/min/forwardable.js
    application/js/vendor/JS.Class-2.1.5/min/hash.js
    application/js/vendor/JS.Class-2.1.5/min/linked_list.js
    application/js/vendor/JS.Class-2.1.5/min/loader.js
    application/js/vendor/JS.Class-2.1.5/min/method_chain.js
    application/js/vendor/JS.Class-2.1.5/min/observable.js
    application/js/vendor/JS.Class-2.1.5/min/package.js
    application/js/vendor/JS.Class-2.1.5/min/proxy.js
    application/js/vendor/JS.Class-2.1.5/min/ruby.js
    application/js/vendor/JS.Class-2.1.5/min/set.js
    application/js/vendor/JS.Class-2.1.5/min/stack_trace.js
    application/js/vendor/JS.Class-2.1.5/min/state.js
    application/js/vendor/JS.Class-2.1.5/min/stdlib.js
    application/js/vendor/crypto-2.3.0-crypto.js
    application/js/vendor/crypto-2.3.0-sha1.js
    application/js/vendor/diff_match_patch.js
    application/js/vendor/jquery-1.6.2.min.js
    application/js/vendor/jquery-1.7.1.min.js
    application/js/vendor/jquery-ui-1.8.16.custom.min.js
    application/js/vendor/jquery-ui-1.8.18.custom.min.js
    application/js/vendor/jquery-ui-1.8.9.custom.min.js
    application/js/views.js
    application/js/views/box_view.js
    application/js/views/page_piece_view.js
    application/js/views/page_view.js
    application/js/views/piece_view.js
    application/static/diagonal-texture.png
    application/static/editing-0-noise.png
    application/static/editing-1-noise.png
    application/static/editing-textarea-resize-s.png
    application/static/editing-texture-1.png
    application/static/editing-texture.png
    application/static/editing-toolbar-shadow-bottom.png
    application/static/editing-toolbar-shadow-top.png
    application/static/favicon.ico
    application/static/font/fontawesome-webfont.ttf
    application/static/inner-glow.png
    application/static/item-buttons-highlight.png
    application/static/item-buttons.png
    application/static/location-arrow.png
    application/static/logo-400px-transparent.png
    application/static/loop_alt1-white.svg
    application/static/loop_alt1.svg
    application/static/missing.png
    application/static/orange-down-arrow.png
    application/static/page-browser-next.png
    application/static/paper-texture-dark.png
    application/static/plus-box.png
    application/static/plus_alt.svg
    application/static/px.gif
    application/static/select-arrow-root.png
    application/static/select-arrow.png
    application/static/slot-down-arrow.png
    application/static/slot-up-arrow.png
    application/static/splash.png
    application/static/spontaneous-states.png
    application/static/spontaneous.png
    application/static/spot.png
    application/static/spot.svg
    application/static/texture.png
    application/views/index.erb
    application/views/login.erb
    application/views/schema_modification_error.html.erb
    application/views/unsupported.erb
    bin/limit-upload
    bin/spot
    bin/unlimit-upload
    config/nginx.conf
    db/migrations/20100610142136_init.rb
    db/migrations/20101130104334_timestamps.rb
    db/migrations/20101202113205_site_publishing_flags.rb
    db/migrations/20101206124543_aliases.rb
    db/migrations/20110201133550_visibility.rb
    db/migrations/20110209152710_users_and_groups.rb
    db/migrations/20110215133910_boxes.rb
    db/migrations/20110521114145_remove_slots_and_entries.rb
    db/migrations/20110604192145_rename_schema_id_columns.rb
    db/migrations/20110805141925_rename_site_to_state.rb
    db/migrations/20120106171423_visibility_path.rb
    db/migrations/20120107124541_owner_id.rb
    db/migrations/20120305112647_site_modification_time.rb
    db/migrations/20120418153903_add_ownership_of_content.rb
    db/migrations/20120423175416_add_pending_modifications.rb
    db/migrations/20120525164947_add_field_versions.rb
    docs/recipe-interface-screenshot.png
    lib/cutaneous.rb
    lib/cutaneous/context_helper.rb
    lib/cutaneous/preview_context.rb
    lib/cutaneous/preview_renderer.rb
    lib/cutaneous/publish_context.rb
    lib/cutaneous/publish_renderer.rb
    lib/cutaneous/publish_template.rb
    lib/cutaneous/publish_token_parser.rb
    lib/cutaneous/renderer.rb
    lib/cutaneous/request_context.rb
    lib/cutaneous/request_renderer.rb
    lib/cutaneous/request_template.rb
    lib/cutaneous/request_token_parser.rb
    lib/cutaneous/token_parser.rb
    lib/sequel/plugins/content_table_inheritance.rb
    lib/sequel/plugins/scoped_table_name.rb
    lib/spontaneous.rb
    lib/spontaneous/application.rb
    lib/spontaneous/application/feature.rb
    lib/spontaneous/application/plugin.rb
    lib/spontaneous/box.rb
    lib/spontaneous/box_style.rb
    lib/spontaneous/capistrano.rb
    lib/spontaneous/capistrano/deploy.rb
    lib/spontaneous/capistrano/sync.rb
    lib/spontaneous/change.rb
    lib/spontaneous/cli.rb
    lib/spontaneous/cli/adapter.rb
    lib/spontaneous/cli/base.rb
    lib/spontaneous/cli/console.rb
    lib/spontaneous/cli/media.rb
    lib/spontaneous/cli/server.rb
    lib/spontaneous/cli/site.rb
    lib/spontaneous/cli/sync.rb
    lib/spontaneous/cli/tasks.rb
    lib/spontaneous/cli/user.rb
    lib/spontaneous/collections/box_set.rb
    lib/spontaneous/collections/change_set.rb
    lib/spontaneous/collections/entry_set.rb
    lib/spontaneous/collections/field_set.rb
    lib/spontaneous/collections/prototype_set.rb
    lib/spontaneous/collections/style_set.rb
    lib/spontaneous/config.rb
    lib/spontaneous/constants.rb
    lib/spontaneous/content.rb
    lib/spontaneous/content_query.rb
    lib/spontaneous/errors.rb
    lib/spontaneous/extensions/array.rb
    lib/spontaneous/extensions/class.rb
    lib/spontaneous/extensions/enumerable.rb
    lib/spontaneous/extensions/hash.rb
    lib/spontaneous/extensions/json.rb
    lib/spontaneous/extensions/kernel.rb
    lib/spontaneous/extensions/nil.rb
    lib/spontaneous/extensions/object.rb
    lib/spontaneous/extensions/object_space.rb
    lib/spontaneous/extensions/string.rb
    lib/spontaneous/facet.rb
    lib/spontaneous/field_types.rb
    lib/spontaneous/field_types/date_field.rb
    lib/spontaneous/field_types/field.rb
    lib/spontaneous/field_types/file_field.rb
    lib/spontaneous/field_types/image_field.rb
    lib/spontaneous/field_types/location_field.rb
    lib/spontaneous/field_types/long_string_field.rb
    lib/spontaneous/field_types/markdown_field.rb
    lib/spontaneous/field_types/select_field.rb
    lib/spontaneous/field_types/string_field.rb
    lib/spontaneous/field_types/webvideo_field.rb
    lib/spontaneous/field_version.rb
    lib/spontaneous/generators.rb
    lib/spontaneous/generators/page.rb
    lib/spontaneous/generators/page/inline.html.cut
    lib/spontaneous/generators/page/page.html.cut.tt
    lib/spontaneous/generators/page/page.rb.tt
    lib/spontaneous/generators/site.rb
    lib/spontaneous/generators/site/.gitignore
    lib/spontaneous/generators/site/Capfile.tt
    lib/spontaneous/generators/site/Gemfile.tt
    lib/spontaneous/generators/site/Rakefile.tt
    lib/spontaneous/generators/site/config/back.ru
    lib/spontaneous/generators/site/config/boot.rb
    lib/spontaneous/generators/site/config/database.yml.tt
    lib/spontaneous/generators/site/config/deploy.rb.tt
    lib/spontaneous/generators/site/config/environment.rb.tt
    lib/spontaneous/generators/site/config/environments/development.rb.tt
    lib/spontaneous/generators/site/config/environments/production.rb.tt
    lib/spontaneous/generators/site/config/front.ru
    lib/spontaneous/generators/site/config/indexes.rb.tt
    lib/spontaneous/generators/site/config/user_levels.yml
    lib/spontaneous/generators/site/lib/site.rb.tt
    lib/spontaneous/generators/site/lib/tasks/site.rake.tt
    lib/spontaneous/generators/site/public/css/site.scss
    lib/spontaneous/generators/site/public/favicon.ico
    lib/spontaneous/generators/site/public/js/.empty_directory
    lib/spontaneous/generators/site/public/js/site.js
    lib/spontaneous/generators/site/public/robots.txt
    lib/spontaneous/generators/site/schema/.map
    lib/spontaneous/generators/site/schema/box.rb.tt
    lib/spontaneous/generators/site/schema/page.rb.tt
    lib/spontaneous/generators/site/schema/piece.rb.tt
    lib/spontaneous/generators/site/templates/layouts/standard.html.cut.tt
    lib/spontaneous/image_size.rb
    lib/spontaneous/json.rb
    lib/spontaneous/layout.rb
    lib/spontaneous/loader.rb
    lib/spontaneous/logger.rb
    lib/spontaneous/media.rb
    lib/spontaneous/media/file.rb
    lib/spontaneous/page.rb
    lib/spontaneous/page_controller.rb
    lib/spontaneous/page_piece.rb
    lib/spontaneous/paths.rb
    lib/spontaneous/permissions.rb
    lib/spontaneous/permissions/access_group.rb
    lib/spontaneous/permissions/access_key.rb
    lib/spontaneous/permissions/user.rb
    lib/spontaneous/permissions/user_level.rb
    lib/spontaneous/piece.rb
    lib/spontaneous/plugins/aliases.rb
    lib/spontaneous/plugins/allowed_types.rb
    lib/spontaneous/plugins/application/facets.rb
    lib/spontaneous/plugins/application/features.rb
    lib/spontaneous/plugins/application/paths.rb
    lib/spontaneous/plugins/application/render.rb
    lib/spontaneous/plugins/application/serialisation.rb
    lib/spontaneous/plugins/application/state.rb
    lib/spontaneous/plugins/application/system.rb
    lib/spontaneous/plugins/boxes.rb
    lib/spontaneous/plugins/controllers.rb
    lib/spontaneous/plugins/entries.rb
    lib/spontaneous/plugins/entry.rb
    lib/spontaneous/plugins/field/editor_class.rb
    lib/spontaneous/plugins/fields.rb
    lib/spontaneous/plugins/instance_code.rb
    lib/spontaneous/plugins/layouts.rb
    lib/spontaneous/plugins/media.rb
    lib/spontaneous/plugins/modifications.rb
    lib/spontaneous/plugins/page/formats.rb
    lib/spontaneous/plugins/page/request.rb
    lib/spontaneous/plugins/page/site_timestamps.rb
    lib/spontaneous/plugins/page_search.rb
    lib/spontaneous/plugins/page_tree.rb
    lib/spontaneous/plugins/paths.rb
    lib/spontaneous/plugins/permissions.rb
    lib/spontaneous/plugins/prototypes.rb
    lib/spontaneous/plugins/publishing.rb
    lib/spontaneous/plugins/render.rb
    lib/spontaneous/plugins/schema_hierarchy.rb
    lib/spontaneous/plugins/schema_id.rb
    lib/spontaneous/plugins/schema_title.rb
    lib/spontaneous/plugins/serialisation.rb
    lib/spontaneous/plugins/site/features.rb
    lib/spontaneous/plugins/site/helpers.rb
    lib/spontaneous/plugins/site/hooks.rb
    lib/spontaneous/plugins/site/instance.rb
    lib/spontaneous/plugins/site/level.rb
    lib/spontaneous/plugins/site/map.rb
    lib/spontaneous/plugins/site/paths.rb
    lib/spontaneous/plugins/site/publishing.rb
    lib/spontaneous/plugins/site/schema.rb
    lib/spontaneous/plugins/site/search.rb
    lib/spontaneous/plugins/site/selectors.rb
    lib/spontaneous/plugins/site/state.rb
    lib/spontaneous/plugins/site/storage.rb
    lib/spontaneous/plugins/site/url.rb
    lib/spontaneous/plugins/site_map.rb
    lib/spontaneous/plugins/styles.rb
    lib/spontaneous/plugins/supertype.rb
    lib/spontaneous/plugins/visibility.rb
    lib/spontaneous/prototypes/box_prototype.rb
    lib/spontaneous/prototypes/field_prototype.rb
    lib/spontaneous/prototypes/layout_prototype.rb
    lib/spontaneous/prototypes/style_prototype.rb
    lib/spontaneous/publishing.rb
    lib/spontaneous/publishing/event_client.rb
    lib/spontaneous/publishing/immediate.rb
    lib/spontaneous/publishing/simultaneous.rb
    lib/spontaneous/publishing/threaded.rb
    lib/spontaneous/rack.rb
    lib/spontaneous/rack/around_back.rb
    lib/spontaneous/rack/around_front.rb
    lib/spontaneous/rack/around_preview.rb
    lib/spontaneous/rack/assets.rb
    lib/spontaneous/rack/authentication.rb
    lib/spontaneous/rack/back.rb
    lib/spontaneous/rack/cacheable_file.rb
    lib/spontaneous/rack/cookie_authentication.rb
    lib/spontaneous/rack/css.rb
    lib/spontaneous/rack/event_source.rb
    lib/spontaneous/rack/fiber_pool.rb
    lib/spontaneous/rack/front.rb
    lib/spontaneous/rack/helpers.rb
    lib/spontaneous/rack/http.rb
    lib/spontaneous/rack/js.rb
    lib/spontaneous/rack/media.rb
    lib/spontaneous/rack/public.rb
    lib/spontaneous/rack/query_authentication.rb
    lib/spontaneous/rack/reloader.rb
    lib/spontaneous/rack/sse.rb
    lib/spontaneous/rack/static.rb
    lib/spontaneous/rack/user_helpers.rb
    lib/spontaneous/render.rb
    lib/spontaneous/render/assets.rb
    lib/spontaneous/render/assets/compression.rb
    lib/spontaneous/render/context_base.rb
    lib/spontaneous/render/development_renderer.rb
    lib/spontaneous/render/engine.rb
    lib/spontaneous/render/helpers.rb
    lib/spontaneous/render/helpers/classes_helper.rb
    lib/spontaneous/render/helpers/conditional_comment_helper.rb
    lib/spontaneous/render/helpers/script_helper.rb
    lib/spontaneous/render/helpers/stylesheet_helper.rb
    lib/spontaneous/render/output.rb
    lib/spontaneous/render/output/html.rb
    lib/spontaneous/render/output/plain.rb
    lib/spontaneous/render/preview_context.rb
    lib/spontaneous/render/preview_renderer.rb
    lib/spontaneous/render/publish_context.rb
    lib/spontaneous/render/published_renderer.rb
    lib/spontaneous/render/publishing_renderer.rb
    lib/spontaneous/render/render_cache.rb
    lib/spontaneous/render/renderer.rb
    lib/spontaneous/render/request_context.rb
    lib/spontaneous/revision.rb
    lib/spontaneous/schema.rb
    lib/spontaneous/schema/schema_modification.rb
    lib/spontaneous/schema/uid.rb
    lib/spontaneous/schema/uid_map.rb
    lib/spontaneous/search.rb
    lib/spontaneous/search/compound_indexer.rb
    lib/spontaneous/search/database.rb
    lib/spontaneous/search/field.rb
    lib/spontaneous/search/index.rb
    lib/spontaneous/search/results.rb
    lib/spontaneous/server.rb
    lib/spontaneous/site.rb
    lib/spontaneous/state.rb
    lib/spontaneous/storage.rb
    lib/spontaneous/storage/backend.rb
    lib/spontaneous/storage/cloud.rb
    lib/spontaneous/storage/local.rb
    lib/spontaneous/style.rb
    lib/spontaneous/tasks.rb
    lib/spontaneous/tasks/database.rake
    lib/spontaneous/utils.rb
    lib/spontaneous/utils/database.rb
    lib/spontaneous/utils/database/mysql_dumper.rb
    lib/spontaneous/utils/database/postgres_dumper.rb
    lib/spontaneous/utils/smart_quotes.rb
    lib/spontaneous/utils/smush_it.rb
    lib/spontaneous/version.rb
    spontaneous.gemspec
    test/disabled/test_slots.rb
    test/experimental/test_features.rb
    test/fixtures/application/js/test.js
    test/fixtures/application/static/favicon.ico
    test/fixtures/application/static/test.html
    test/fixtures/application/views/index.erb
    test/fixtures/assets/public1/css/a.scss
    test/fixtures/assets/public1/js/a.js
    test/fixtures/assets/public1/js/m.coffee
    test/fixtures/assets/public2/css/b.scss
    test/fixtures/assets/public2/css/c.css
    test/fixtures/assets/public2/js/b.js
    test/fixtures/assets/public2/js/c.js
    test/fixtures/assets/public2/js/n.coffee
    test/fixtures/back/config/user_levels.yml
    test/fixtures/back/public/css/sass_include.scss
    test/fixtures/back/public/css/sass_template.scss
    test/fixtures/back/public/js/coffeescript.coffee
    test/fixtures/back/public/test.html
    test/fixtures/back/templates/layouts/standard.css.cut
    test/fixtures/back/templates/layouts/standard.html.cut
    test/fixtures/back/templates/layouts/standard.js.cut
    test/fixtures/config/config/environment.rb
    test/fixtures/config/config/environments/development.rb
    test/fixtures/config/config/environments/production.rb
    test/fixtures/config/config/environments/staging.rb
    test/fixtures/example_application/Gemfile
    test/fixtures/example_application/Gemfile.lock
    test/fixtures/example_application/Rakefile
    test/fixtures/example_application/config/back.rb
    test/fixtures/example_application/config/back.ru
    test/fixtures/example_application/config/back.yml
    test/fixtures/example_application/config/boot.rb
    test/fixtures/example_application/config/database.yml
    test/fixtures/example_application/config/environment.rb
    test/fixtures/example_application/config/environments/development.rb
    test/fixtures/example_application/config/environments/production.rb
    test/fixtures/example_application/config/environments/staging.rb
    test/fixtures/example_application/config/front.rb
    test/fixtures/example_application/config/front.ru
    test/fixtures/example_application/config/front.yml
    test/fixtures/example_application/config/schema.yml
    test/fixtures/example_application/config/unicorn.rb
    test/fixtures/example_application/config/user_levels.yml
    test/fixtures/example_application/public/css/test.css
    test/fixtures/example_application/public/favicon.ico
    test/fixtures/example_application/public/js/test.js
    test/fixtures/example_application/public/test.html
    test/fixtures/example_application/schema/client_project.rb
    test/fixtures/example_application/schema/client_projects.rb
    test/fixtures/example_application/schema/home_page.rb
    test/fixtures/example_application/schema/info_page.rb
    test/fixtures/example_application/schema/inline_image.rb
    test/fixtures/example_application/schema/page.rb
    test/fixtures/example_application/schema/piece.rb
    test/fixtures/example_application/schema/project.rb
    test/fixtures/example_application/schema/project_image.rb
    test/fixtures/example_application/schema/projects_page.rb
    test/fixtures/example_application/schema/text.rb
    test/fixtures/example_application/templates/client_project.html.cut
    test/fixtures/example_application/templates/client_project/images.html.cut
    test/fixtures/example_application/templates/client_projects.html.cut
    test/fixtures/example_application/templates/info_page/inline.html.cut
    test/fixtures/example_application/templates/inline_image.html.cut
    test/fixtures/example_application/templates/layouts/home.html.cut
    test/fixtures/example_application/templates/layouts/info.html.cut
    test/fixtures/example_application/templates/layouts/project.html.cut
    test/fixtures/example_application/templates/layouts/projects.html.cut
    test/fixtures/example_application/templates/layouts/standard.html.cut
    test/fixtures/example_application/templates/project.html.cut
    test/fixtures/example_application/templates/project/inline.html.cut
    test/fixtures/example_application/templates/project_image.html.cut
    test/fixtures/example_application/templates/text.html.cut
    test/fixtures/fields/youtube_api_response.xml
    test/fixtures/helpers/templates/layouts/standard.html.cut
    test/fixtures/helpers/templates/layouts/standard.mobile.cut
    test/fixtures/images/rose.greyscale.jpg
    test/fixtures/images/rose.jpg
    test/fixtures/images/size.gif
    test/fixtures/images/size.jpg
    test/fixtures/images/size.png24
    test/fixtures/images/size.png8
    test/fixtures/images/vimlogo.pdf
    test/fixtures/layouts/layouts/custom1.html.cut
    test/fixtures/layouts/layouts/custom1.pdf.cut
    test/fixtures/layouts/layouts/custom1.xml.cut
    test/fixtures/layouts/layouts/custom2.html.cut
    test/fixtures/layouts/layouts/custom3.html.cut
    test/fixtures/layouts/layouts/custom4.html.cut
    test/fixtures/layouts/layouts/standard.html.cut
    test/fixtures/media/101/003/rose.jpg
    test/fixtures/outputs/templates/layouts/standard.atom.cut
    test/fixtures/permissions/config/user_levels.yml
    test/fixtures/permissions/media/image.jpg
    test/fixtures/plugins/schema_plugin/init.rb
    test/fixtures/plugins/schema_plugin/public/css/plugin.css
    test/fixtures/plugins/schema_plugin/public/js/plugin.js
    test/fixtures/plugins/schema_plugin/public/static.html
    test/fixtures/plugins/schema_plugin/public/subdir/image.gif
    test/fixtures/plugins/schema_plugin/public/subdir/include1.scss
    test/fixtures/plugins/schema_plugin/public/subdir/sass.scss
    test/fixtures/plugins/schema_plugin/public/subdir/sass/include2.scss
    test/fixtures/plugins/schema_plugin/schema/external.rb
    test/fixtures/plugins/schema_plugin/templates/external.html.cut
    test/fixtures/plugins/schema_plugin/templates/from_plugin.html.cut
    test/fixtures/plugins/schema_plugin/templates/layouts/from_plugin.html.cut
    test/fixtures/public/templates/layouts/default.html.cut
    test/fixtures/public/templates/layouts/default.pdf.cut
    test/fixtures/public/templates/layouts/default.rss.cut
    test/fixtures/public/templates/layouts/dynamic.html.cut
    test/fixtures/public/templates/layouts/standard.html.cut
    test/fixtures/schema/before.yml
    test/fixtures/schema/resolvable.yml
    test/fixtures/schema/schema.yml
    test/fixtures/schema_modification/config/database.yml
    test/fixtures/schema_modification/config/environment.rb
    test/fixtures/schema_modification/schema/box.rb
    test/fixtures/schema_modification/schema/custom_box.rb
    test/fixtures/schema_modification/schema/page.rb
    test/fixtures/schema_modification/schema/piece.rb
    test/fixtures/search/config/database.yml
    test/fixtures/search/config/indexes.rb
    test/fixtures/serialisation/class_hash.yaml.erb
    test/fixtures/serialisation/root_hash.yaml.erb
    test/fixtures/sharding/rose.jpg
    test/fixtures/sharding/xaa
    test/fixtures/sharding/xab
    test/fixtures/sharding/xac
    test/fixtures/sharding/xad
    test/fixtures/sharding/xae
    test/fixtures/sharding/xaf
    test/fixtures/sharding/xag
    test/fixtures/storage/cloud/environment.rb
    test/fixtures/storage/default/environment.rb
    test/fixtures/styles/box_a.html.cut
    test/fixtures/styles/box_a/runny.html.cut
    test/fixtures/styles/named2.html.cut
    test/fixtures/styles/orange/apple.html.cut
    test/fixtures/styles/template_class.epub.cut
    test/fixtures/styles/template_class.html.cut
    test/fixtures/styles/template_class.pdf.cut
    test/fixtures/styles/template_class/named1.html.cut
    test/fixtures/styles/template_class/results.html.cut
    test/fixtures/styles/template_class/walky.html.cut
    test/fixtures/styles/template_sub_class1.html.cut
    test/fixtures/templates/aliases/a/a_style.html.cut
    test/fixtures/templates/aliases/a/page.html.cut
    test/fixtures/templates/aliases/a_alias/a_alias_style.html.cut
    test/fixtures/templates/aliases/layouts/b.html.cut
    test/fixtures/templates/aliases/layouts/b_alias.html.cut
    test/fixtures/templates/aliases/layouts/c_alias.html.cut
    test/fixtures/templates/boxes/blank_content/things.html.cut
    test/fixtures/templates/boxes/my_box_class/christy.html.cut
    test/fixtures/templates/boxes/thangs.html.cut
    test/fixtures/templates/boxes/with_template_box.html.cut
    test/fixtures/templates/content/include.html.cut
    test/fixtures/templates/content/include_dir.html.cut
    test/fixtures/templates/content/included.epub.cut
    test/fixtures/templates/content/included.html.cut
    test/fixtures/templates/content/partial/included.html.cut
    test/fixtures/templates/content/preprocess.html.cut
    test/fixtures/templates/content/second.html.cut
    test/fixtures/templates/content/template.epub.cut
    test/fixtures/templates/content/template.html.cut
    test/fixtures/templates/default_style_class.html.cut
    test/fixtures/templates/direct.html.cut
    test/fixtures/templates/engine/braces.html.cut
    test/fixtures/templates/engine/multiline.html.cut
    test/fixtures/templates/extended/grandparent.html.cut
    test/fixtures/templates/extended/main.html.cut
    test/fixtures/templates/extended/parent.html.cut
    test/fixtures/templates/extended/partial.html.cut
    test/fixtures/templates/extended/partial_with_locals.html.cut
    test/fixtures/templates/extended/with_includes.html.cut
    test/fixtures/templates/extended/with_includes_and_locals.html.cut
    test/fixtures/templates/layouts/entries.html.cut
    test/fixtures/templates/layouts/page_style.html.cut
    test/fixtures/templates/layouts/params.html.cut
    test/fixtures/templates/layouts/preview_render.html.cut
    test/fixtures/templates/layouts/standard_page.html.cut
    test/fixtures/templates/layouts/subdir_style.html.cut
    test/fixtures/templates/layouts/template_params.html.cut
    test/fixtures/templates/layouts/variables.html.cut
    test/fixtures/templates/page_class/inline_style.html.cut
    test/fixtures/templates/preview_render/inline.html.cut
    test/fixtures/templates/preview_render/variables.html.cut
    test/fixtures/templates/publishing/templates/layouts/dynamic.html.cut
    test/fixtures/templates/publishing/templates/layouts/dynamic.rtf.cut
    test/fixtures/templates/publishing/templates/layouts/static.html.cut
    test/fixtures/templates/template_class/anonymous_style.html.cut
    test/fixtures/templates/template_class/another_template.html.cut
    test/fixtures/templates/template_class/complex_template.html.cut
    test/fixtures/templates/template_class/complex_template.pdf.cut
    test/fixtures/templates/template_class/default_template_style.html.cut
    test/fixtures/templates/template_class/images_with_template.html.cut
    test/fixtures/templates/template_class/slots_template.html.cut
    test/fixtures/templates/template_class/slots_template.pdf.cut
    test/fixtures/templates/template_class/this_template.epub.cut
    test/fixtures/templates/template_class/this_template.html.cut
    test/fixtures/templates/template_class/this_template.pdf.cut
    test/fixtures/templates/with_default_style_class.html.cut
    test/functional/test_application.rb
    test/functional/test_back.rb
    test/functional/test_front.rb
    test/javascript/env.js
    test/javascript/test_dom.rb
    test/javascript/test_markdown.rb
    test/support/custom_matchers.rb
    test/support/timing.rb
    test/test_helper.rb
    test/test_javascript.rb
    test/ui/test_page_editing.rb
    test/ui_helper.rb
    test/unit/test_alias.rb
    test/unit/test_assets.rb
    test/unit/test_async.rb
    test/unit/test_authentication.rb
    test/unit/test_boxes.rb
    test/unit/test_changesets.rb
    test/unit/test_config.rb
    test/unit/test_content.rb
    test/unit/test_content_inheritance.rb
    test/unit/test_cutaneous.rb
    test/unit/test_extensions.rb
    test/unit/test_fields.rb
    test/unit/test_formats.rb
    test/unit/test_generators.rb
    test/unit/test_helpers.rb
    test/unit/test_image_size.rb
    test/unit/test_images.rb
    test/unit/test_layouts.rb
    test/unit/test_logger.rb
    test/unit/test_media.rb
    test/unit/test_modifications.rb
    test/unit/test_page.rb
    test/unit/test_permissions.rb
    test/unit/test_piece.rb
    test/unit/test_plugins.rb
    test/unit/test_prototype_set.rb
    test/unit/test_prototypes.rb
    test/unit/test_publishing.rb
    test/unit/test_render.rb
    test/unit/test_revisions.rb
    test/unit/test_schema.rb
    test/unit/test_search.rb
    test/unit/test_serialisation.rb
    test/unit/test_site.rb
    test/unit/test_storage.rb
    test/unit/test_structure.rb
    test/unit/test_styles.rb
    test/unit/test_table_scoping.rb
    test/unit/test_templates.rb
    test/unit/test_type_hierarchy.rb
    test/unit/test_visibility.rb
  ]
  # = MANIFEST =

  ## Test files will be grabbed from the file list. Make sure the path glob
  ## matches what you actually use.
  s.test_files = s.files.select { |path| path =~ /^test\/test_.*\.rb/ }
end
