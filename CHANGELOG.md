
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