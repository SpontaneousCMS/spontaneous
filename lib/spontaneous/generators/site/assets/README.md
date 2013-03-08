Assets
======

Spontaneous uses [Sprockets](https://github.com/sstephenson/sprockets)
to manage assets.

Place any stylesheet, javascript or images under "assets" (following any
structure that you like) and then during publishing Spontaneous will bundle,
compile, compress and fingerprint these files.

To reference assets within templates use the `asset_path` helper which will
intelligently translate Sprocket's "logical paths" into the compressed &
fingerprinted version.

Within SASS templates Sprockets provides a set of useful helpers including
`asset_url` and `asset_data_uri`.

(See: <https://github.com/sstephenson/sprockets/blob/master/lib/sprockets/sass_functions.rb>.)

For more information on using Sprockets see its [GitHub page](https://github.com/sstephenson/sprockets).
