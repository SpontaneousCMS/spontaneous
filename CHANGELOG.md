## 0.2.0.beta10, released 2014-XX-XX

#### New Features

- Enabled previewing of private pages

#### Fixes

- Front server no longer needs restarting to pick up a new revision in development mode (https://github.com/SpontaneousCMS/spontaneous/issues/47)

## 0.2.0.beta9, released 2014-10-30

#### Fixes

- Revert some changes to the asset compilation step to fix publishing in development mode.

## 0.2.0.beta8, released 2014-10-29

#### Fixes

- Include `-webkit` prefixed versions of all flexbox properties to fix display in Safari
- Fix image drag & drop in Chrome -- revoking blob URLs immediately now results in a broken image
- Remove all references to `Page#path` in initialization to avoid trying to resolve the full path before the pages' parents have been assigned
- Explicitly copy compiled assets to the new published revision using a new core publish step rather than hijack the asset compilation/resolution step. This ensures that dependencies are copied on a second publish.
- Fix layout of box tabs by using appropriate mixins to apply `-webkit` prefixed styles

## 0.2.0.beta7, released 2014-09-03

#### Fixes

- Bring Rake dependency up-to-date

## 0.2.0.beta6, released 2014-08-06

#### New Features

- Spontaneous now requires Ruby 2
- SQLite 3 support added and set as default db for new sites
- Startup now requires each file in the `config/initializers` directory after intializing and configuring the site instance. This allows for Rails-style extensions to the site state & functionality.
- Publishing is now managed by a configurable pipeline declared in `config/initializers/publishing.rb`. This greatly clarifies the publishing process and also allows for the insertion of custom actions that will run on each publish.
- The modification state of pages is now calculated using the actual state of the page's content, rather than just comparing the modification date with the date of the last publish. This means that making & then undoing a change won't result in the page appearing in the modified list.
- UIDs have been replaced by the concept of 'singleton' classes which return a single instance based on the type name or a set of labels. This removes the last bit of developer-controlled content from the database & hence resolves issues around publishing pages purely for developer originated UID changes.
- Page types can now be configured to render the content of another page as their own using the Page::renders method.
- You can now add multiple aliases at once, selecting individually or by drag-selecting or shift-selecting ranges & groups of items.

#### Misc

- The site generator now takes the current user name as the default
  database user for postgres installs. This will hopefully make installation easier.
- Changed dependency from 'bcrypt-ruby' to 'bcrypt' (as instructed)
- Made bundler version dependency more explicit (as instructed)
- Removed warning about declaring task 'generate_site'
- Add some documentation about templating into the generated layout
- Replaced outdated flexible box CSS properties with new style ones (`display: box` => `display: flex`)
- Add index to `content.target_id` to improve performance of searches for aliases
- Content associations now use prepared statements which significantly speeds up page load & site render
- Slug change propagation and modification tracking no longer rely on mystery instance variable flags
- The editing interface now has some feedback/a loading animation when navigating between pages
- Publishing re-uses compiled assets if they exist. Assets are compiled once per deploy rather than once per publish. This cuts a significant amount of time off the publishing step (especially for small sites)
- The contents of boxes now render in batches as you scroll, rather than rendering every single entry at page load. This speeds up the display of pages with a lot of content.
- Using Velocity.js for animation where possible for smoother transitions
- Better support for private roots


#### Fixes

- Fix broken publish command
- Piece aliases now link using the id of the owning page of the target, rather than the id of the target itself
- Rendering a private root no longer crashes in the `navigation` helper
- Directly rendering a page instance within a tenplate no longer results in a page-within-page situation (context instances now call a separate #render_inline method which passes the call onto a page's containing entry)
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