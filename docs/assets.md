# Asset handling

Spontaneous is attempting to take a very light-touch relationship with asset
management. Front-end tech moves too quickly for integration libraries to
keep up, so front-end tech should manage front-end code. Webpack, gulp, grunt
win over sprockets.

## The contract

So instead we work with the following contract:

- You keep your asset sources in `<site root>/assets` -- they can be in any structure.

- Your pipeline of choice compiles your assets to the given output directory
  (`<site-root>/private/assets` in development mode)

- Your pipeline **must** either:
  - preserve filepaths, or
  - record filename/path changes to a `manifest.json` file in the root of the
    given output directory (e.g. `private/assets/manifest.json`)

## Configuration

Configuration of the pipeline is done in `config/initializers/assets.rb`. This
file defines 3 site-level procs that are used in development to watch for
changes to the asset files & trigger a re-compile, during deployment to compile
a production ready version of the assets and finally map a file-name &
file-hash tuple to a fingerprinted filename.

Example procs are included in the generated initializer file.

## manifest.json

This is a simple JSON-encoded hash that represents a map of an asset file's
original name to it's fingerprinted version. e.g.

```json
{
  "js/site.js": "js/site-85de935cdb20.js",
  "css/site.css": "css/site-42423ff7fb43.css"
}
```

Using this the templating system can map the file `js/site.js` to the compiled
asset on disk at `js/site-f75d8a1e994100cc03f2d1e1209a17e6.js`.

```html
<script src="${ asset_path 'js/site.js' }"></script>
```

Becomes:

```html
<script src="js/site-f75d8a1e994100cc03f2d1e1209a17e6.js"></script>
```

# Fingerprinting

If you can fingerprint assets during your compilation then you should. If you
want to e.g. refer to image assets from within your CSS then you **must**
fingerprint those image assets as part of your compilation. If you don't then
the deploy system will do the fingerprinting for you but your CSS files will
still refer to the un-fingerprinted filenames.

This is because in production all assets are completely static so spontaneous
has no ability to re-write paths according to the values in the manifest. The
manifest is only usable by templates rendered by spontaneous as part of the
publishing process.

# Deploy

On deploy any files not included in the manifest.json (and so have their
original file-names & -paths preserved) will be hashed & fingerprinted and an
entry put into the production `manifest.json`. This means that any files you
don't need to process but do need to be included in the asset bundle (e.g.
images) can simply be copied by your asset pipeline command(s) and will
fingerprinted for use in production by the deploy process.

