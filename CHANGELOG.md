## 0.2.0.beta11, released 2015-XX-XX

#### New features

- The previous 'entry_store' based method of recording box contents has been
  replaced with a more natural many-to-one SQL relation.

- There's a new `spot site index` command that can re-generate the search
  indexes based on the currently published content.

- Model classes now have `::each` and `::map` methods for iterating through all
  instances of a type.

- The output store is now responsible for marking a revision as active, which is
  how it should have been all along.

- Assets and static files are now published into the output store, along with
  templates.

#### Misc

- There's now a cli task to re-index the site
- A legacy '/rev' route has been removed from the front Rack app

#### Fixes

- `Box#adopt` now cascades changes to the content path through all the adopted
  contents children. This paves the way for moving content around in the UI...
  A side-effect of this is that an item's `owner_id` is now included in the
  calculation of the current content hash, so there'll be some bad behaviour
  around modification status until this beds in.

- File and image fields now return consistent values for `#blank?` and
  `#empty?`.

- Adding an alias of an invisible target no longer sets creates a bad
  visibility state on the created alias (#57)

- Changing the visibility of the parent of an item with aliases now correctly
  updates the visibility of the aliases.

- The UI correctly reflects the status of all items in the current page
  affected by a visibility change, even if they're in another box.

- Incremental loading of box entries in the UI now works according to the
  height of the box contents, rather than arbitrary counts. This improves the
  behaviour of long lists of entries.

## 0.2.0.beta10, released 2015-03-20

Is it wise to release a new version during a solar eclipse?

#### New Features

- Enabled previewing of private pages within the CMS. Previously this would
  invoke some Inception-like preview-within-preview loop

- Boxes can now define a `path_origin` function that returns a `Content::Page`
  instance or a string which sets the root path for all pages added to it. This
  allows for your content & path hierarchies to differ (e.g. having child pages
  of the `/bands` page, e.g. `/bands/the-beatles` appear publicly at the root
  of the site i.e. `/the-beatles`).

- Page types can set a custom default slug root so that instead of being added
  as `page-YMD-HMS` they can be configured to default to `something-YMD-HMS` by
  overriding the value returned by `Content::Page#default_slug_root`.

- You can now get a list of content ids for a box using the `Box#ids` method

- The db connection can now be set using a `DATABASE_URL` env setting

- File and Image fields now generate their URLs dynamically. In the case of
  cloud hosted media this means you can change the way you address the media
  without having to regenerate the values e.g. in the case that you move from a
  direct S3 bucket to a CDN. You can also use any object that responds to
  `#call(path)` to generate the URLs which opens the door to splitting your
  media across multiple asset hosts.

- Pages can now declare 'wildcard' routes without namespaces which makes them
  more like standard controllers. E.g. declaring

        controller do
          get '/wibble/:id' do ... end
        end

    will allow a page mounted at `/womble` to accept requests to
    `/womble/wibble/23` etc.

- The publish dialogue now has a `Rerender` button that allows developers to
  re-render the site without publishing any content in the case of a
  template/asset change. Great if you need to push a fix but don't want to wait
  for or force the editors to publish something.

- You can now configure some default options for rendering image fields (and
  the default output for `${ image }` no longer includes the width & height by
  default (we’re responsive now, right?)).

#### Misc

- JSON de/en-coding is now handled by [Oj](https://github.com/ohler55/oj) not
  [Yajl](https://lloyd.github.io/yajl/) after some informal testing showed a
  ~50% speed improvement.
- The site initialization has been re-written to improve clarity & reliability
- Capistrano tasks can now be configured to use a custom binary for `rake` and
  `spot` commands
- Boxes now have a `#clear!` method to remove all their contents
- `Content#/` is an alias for `#get` by id
- The db timezone is set to UTC which results in some improved performance
- `Site#inspect` output is less mad
- The asset serving in preview mode has been moved before the authentication
  checks so we aren't running hundreds of db calls just to return some JS and
  images.
- The sprockets context has been given some Rails-compatible methods to help
  with using 3rd party sprockets plugins, e.g. `sprockets-less`.
- Select fields can now have a default value set
- Video fields now have an `aspect_ratio` method
- `spot site rerender` is an alias for `spot site render`

#### Fixes

- Front server no longer needs restarting to pick up a new revision in
  development mode (https://github.com/SpontaneousCMS/spontaneous/issues/47)
- Fixed entry deletion confirmation popup
- `Array#render` now calls `render_inline` rather than `render` so that
  rendering an array of pages doesn’t do mad things.
- The postgres database dumper/loader now works with custom hosts and ports and
  correctly authenticates itself when password authentication is in place
- File & image fields `#blank?` methods now work correctly (and are aliased as
  `#empty?`)
- Removed broken render context implementations of `#first?` and `#last?`
- `spot site init` ensures that the `log` & `tmp` directories exist
- Don't try to set encoding values when there's no content-type header returned
- `asset-data-uri` is now correctly wrapping the result in a `url()` declaration.
- Displaying exceptions in development preview now works
- Second level boxes now correctly show an 'add' toolbar below the last entry
- The 'no changes' message is now a more pleasing size & the spinner goes away

## 0.2.0.beta9, released 2014-10-30

#### Fixes

- Revert some changes to the asset compilation step to fix publishing in
  development mode.

## 0.2.0.beta8, released 2014-10-29

#### Fixes

- Include `-webkit` prefixed versions of all flexbox properties to fix display
  in Safari
- Fix image drag & drop in Chrome -- revoking blob URLs immediately now results
  in a broken image
- Remove all references to `Page#path` in initialization to avoid trying to
  resolve the full path before the pages' parents have been assigned
- Explicitly copy compiled assets to the new published revision using a new
  core publish step rather than hijack the asset compilation/resolution step.
  This ensures that dependencies are copied on a second publish.
- Fix layout of box tabs by using appropriate mixins to apply `-webkit`
  prefixed styles

## 0.2.0.beta7, released 2014-09-03

#### Fixes

- Bring Rake dependency up-to-date

## 0.2.0.beta6, released 2014-08-06

#### New Features

- Spontaneous now requires Ruby 2
- SQLite 3 support added and set as default db for new sites
- Startup now requires each file in the `config/initializers` directory after
  intializing and configuring the site instance. This allows for Rails-style
  extensions to the site state & functionality.
- Publishing is now managed by a configurable pipeline declared in
  `config/initializers/publishing.rb`. This greatly clarifies the publishing
  process and also allows for the insertion of custom actions that will run on
  each publish.
- The modification state of pages is now calculated using the actual state of
  the page's content, rather than just comparing the modification date with the
  date of the last publish. This means that making & then undoing a change
  won't result in the page appearing in the modified list.
- UIDs have been replaced by the concept of 'singleton' classes which return a
  single instance based on the type name or a set of labels. This removes the
  last bit of developer-controlled content from the database & hence resolves
  issues around publishing pages purely for developer originated UID changes.
- Page types can now be configured to render the content of another page as
  their own using the Page::renders method.
- You can now add multiple aliases at once, selecting individually or by
  drag-selecting or shift-selecting ranges & groups of items.

#### Misc

- The site generator now takes the current user name as the default database
  user for postgres installs. This will hopefully make installation easier.
- Changed dependency from 'bcrypt-ruby' to 'bcrypt' (as instructed)
- Made bundler version dependency more explicit (as instructed)
- Removed warning about declaring task 'generate_site'
- Add some documentation about templating into the generated layout
- Replaced outdated flexible box CSS properties with new style ones
  (`display: box` => `display: flex`)
- Add index to `content.target_id` to improve performance of searches for aliases
- Content associations now use prepared statements which significantly speeds
  up page load & site render
- Slug change propagation and modification tracking no longer rely on mystery
  instance variable flags
- The editing interface now has some feedback/a loading animation when
  navigating between pages
- Publishing re-uses compiled assets if they exist. Assets are compiled once
  per deploy rather than once per publish. This cuts a significant amount of
  time off the publishing step (especially for small sites)
- The contents of boxes now render in batches as you scroll, rather than
  rendering every single entry at page load. This speeds up the display of
  pages with a lot of content.
- Using Velocity.js for animation where possible for smoother transitions
- Better support for private roots


#### Fixes

- Fix broken publish command
- Piece aliases now link using the id of the owning page of the target, rather
  than the id of the target itself
- Rendering a private root no longer crashes in the `navigation` helper
- Directly rendering a page instance within a tenplate no longer results in a
  page-within-page situation (context instances now call a separate
  #render_inline method which passes the call onto a page's containing entry)
- Previewing of private pages has been disabled (fixing issue #36)

## 0.2.0.beta5, released 2014-03-18

#### New Features

- Rendering output now goes to a 'output store' class rather than directly to the filesystem.
  The default output store mimics the existing functionality but it can be overridden by
  any Moneta compatible key-value store (e.g. Redis, Memcache). Another step closer to
  Heroku compatibility
- Individual fields can now be hidden in the list view by specifying `list: false` in the
  field definition options
- The navigation helper now accepts options for filtering the list of pages to include
- Page controllers are now full Sinatra instances
- The UI allows for images to be cleared
- Deleting a schema entry now raises a modification error & prompts for confirmation.
  Before this a typo or other error could end up deleting db content
- Modifying the schema will now automatically delete any stray, unmapped, instances from
  the db on deploy
- You can specify the name that a type will appear as in the add list, this enables the same
  basic type to fill many roles without having to subclass it

#### Fixes

- Add tests for & fix current issues with Thor's handling of namespaces
- Fix equality tests for PagePiece's i.e. `PagePiece#target == PagePiece`
- Force every content query to include a list of `schema_id`s so that content entries
  with an invalid/unmapped schema class won't be returned

#### Misc

- Upgrade to Sequel 4.x
- Use the `sequel_pg` gem for better performance with Sequel on Postgres
- Change version specifiers in gemspec to a more liberal range (i.e. "~> 0.x.y" becomes "~> 0.x")
- Improve layout of box tabs to handle cases with many boxes
- `Site[:symbol]` now searches by UID
- The 'back' stack now allows for insertion of Rack apps, rather than just Sinatra apps
- Rename the `:text` fieldtype to `:markdown` to make this clearer
- Rubinius 2 compatibility
- Add a CHANGELOG
