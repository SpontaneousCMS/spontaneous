# The following controls the default render output or image fields.
#
# By default inserting an image field instance into a template like this:
#
#     ${ image }
#
# will output an `img` tag with the image's `src` attribute and an empty `alt`
# value:
#
#     <img src="/path/to/image.jpg" alt="" />
#
# You can override the default attributes by setting an options hash here:
#
Spontaneous::Field::Image.default_attributes = {
  # Include the image's natural width & height by default when rendering an image field
  # size: true,

  # Include only the images’ natural width
  # `true`, `:auto` or `'auto'` are equivalent

  # width: true,

  # Force all images to render at a fixed width (odd but possible)

  # width: 42,

  # Or the same for the image height:

  # height: true,
  # height: 42,

  # Set a default alt attribute (not generally recommended)

  # alt: 'Inappropriate',

  # Or, more usefully, if you want to use a dynamic value based on the field
  # being rendered then pass a proc

  # alt: proc { |field| field.page.title },

  # Or you can set any attribute you want by just adding it in here:

  # crossorigin: 'crossorigin',

  # If you want to set data attributes then you can pass a hash, e.g. to add a data-id attribute
  # based on the images’ owning page e.g.
  #
  #     <img src="..." alt="..." data-id="1234" />
  #
  # You would set a data attribute thusly:

  # data: {
  #   id: proc { |field| field.owner.page.id }
  # },
}
