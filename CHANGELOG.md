## 0.2.0.beta6, released 2014-xx-xx

#### New Features

- Startup now requires each file in the `config/initializers` directory after intializing and configuring the site instance. This allows for Rails-style extensions to the site state & functionality.
- Publishing is now managed by a configurable pipeline declared in `config/initializers/publishing.rb`. This greatly clarifies the publishing process and also allows for the insertion of custom actions that will run on each publish.

#### Misc

- The site generator now takes the current user name as the default
  database user for postgres installs. This will hopefully make installation easier.
- Changed dependency from 'bcrypt-ruby' to 'bcrypt' (as instructed)
- Made bundler version dependency more explicit (as instructed)
- Removed warning about declaring task 'generate_site'
- Add some documentation about templating into the generated layout

#### Fixes

- Fix broken publish command

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