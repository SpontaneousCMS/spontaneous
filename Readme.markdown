![Spontaneous CMS](https://github.com/SpontaneousCMS/spontaneous/raw/master/application/static/logo-400px-transparent.png)

Spontaneous is a revolutionary new content management system that brings the best of Ruby and the best of HTML5 together in one elegant package.

**[http://spontaneous.io](http://spontaneous.io)**

Spontaneous uses a powerful hierarchical system to organise your information.
This breaks out of the bonds of the traditional "title, slug, text" model of
CMS content and instead allows content authors to build complex, highly styled
pages out of simple, easily editable blocks.

## Status

Spontaneous is very much a work-in-progress but is currently almost feature
complete. It has been used with great success on multiple sites. However the
gem release is still marked as 'alpha' because the APIs are in constant flux.


### Features currently supported

- Definition of complex content hierarchies using ORM model-like classes which:
	- Allows for versioning of the metadata using standard CVS systems (i.e. git)
	- Keeps the developer in the text editor
	- Simplifies the interface for the site editor
	- Creates a clear separation of content from schema - changing the site metadata
	- Provides a carefully thought out deployment/upgrade process
	- Keeps interaction between code and db content to a bare minimum and
		separated from normal site editing functions (a 'developer view')
- The schema model allows for 'Page' types which have a URL and 'Piece' types which
	form the content of pages but have no URL
- Each content model sub-class (or 'type') has its own set of defined fields and
	boxes. Each defined box can be configured to allow the addition of any available
	schema type
- Each field has a type. The current field types include simple strings (`:string`),
	long strings (`:text`), Markdown rich text (`:markdown`), images (`:image`, `:photo`),
	web-video (supporting YouTube, Vimeo & Vine URLs), simple file uploads (`:file`),
	date (`:date`), pulldowns (`:select` with static & dynamic options),
	tag fields (`:tag`) and raw HTML code (`:html`)
- Pure separation of content from presentation. Editors write, the CMS lays it out:
  - Page content is split into discrete "pieces" of multiple types (and split into
		multiple 'boxes'). Each of these pieces & boxes has a custom template
	- This enables sophisticated layouts way beyond those possible when constrained
		by WYSIWYG based systems
	- Render content using generated Javascript rather than being limited to HTML
- Sub-classes inherit their superclasses' fields & boxes so schema metadata can
	be coded using DRY principles (and since it's just Ruby code, you can also
	share functionality using Ruby modules)
- An edit-publish cycle that separates saving changes from making them public
- Intelligent publishing step that chooses the most effective method to deliver
	pages, choosing to render & return static HTML pages if possible
- Define multiple outputs (in multiple formats) on a type-by-type basis. Current supported
	formats include HTML, XML, Javascript, PHP, JSON, text... in fact any text-based, template driven
	format you might need
- Powerful hierarchical structures
	- Pages have fields & boxes
	- Boxes have fields and can contain pieces
	- Pieces can have fields and boxes
	- Boxes can contain pages
	- and so on with no depth limit
- An intuitive, attractive & responsive HTML5 interface with
	- Resumable, sharded uploads
	- Upload queueing
	- Drag & drop file uploads
	- Accurate previewing
	- Hierarchical site navigation
	- Context aware markdown editor
-	Use of a schema "map" to enable re-naming of any schema types without affecting the content currently in the database
- Image fields can define any number of 'sizes' each of which is created via a custom ImageMagick
	pipeline (constrcted using [skeptick](https://github.com/maxim/skeptick))
- Template inheritance based on [Django's templating](https://docs.djangoproject.com/en/dev/topics/templates/)
	using [Cutaneous](https://github.com/SpontaneousCMS/cutaneous)
- Asset compilation & minimization through [Sprockets](https://github.com/sstephenson/sprockets)
- Cloud based media storage using [Fog](http://fog.io)
- Powerful fulltext searching powered by [Xapian](http://xapian.org/)
	- Each site can have multiple indexes
	- Each index can be configured to include any subset of the site content on a
		type-by-type, field-by-field basis
- A Rack powered public site including the ability to
	- inject any custom middleware into the request pipeline
	- define an action that will be run on any GET to a particular type (e.g. for
		authenticated access to particular types)
	- define a POST method for individual types
	- define multiple mini-applications per type (e.g. to allow for commenting)
- Powerful access control levels control who can do what
- Embed custom admin applications into the CMS backend

### Aims

The ultimate aim of Spontaneous is to be a CMS system capable of adapting to and
even leading the progress of the internet.

Publishing HTML pages is not enough, which is why the concept of multiple outputs
has been baked into the system right from the start.

Eventually owners of a Spontaneous site will not only be able to publish their
ideas to HTML pages but also use the same content to generate a EPUB & MOBI
e-books, print quality PDFs to send to a printer and proprietry XML or JSON data
for consumption by magazine applications running on tablets.

### Roadmap

#### v1

- **Documentation**
- Finish abstraction of rendering 'filesystem' to allow for rendering to distributed
	key-value stores (WIP)
- Separate the storage configuration from the media filesystem
- Allow configuration of Sprockets to use the defined storage settings
- Abstract the search interface to allow for use of other indexing systems apart
	from Xapian (e.g. Elasticsearch, Lucene etc)
- Support deployment to Heroku (removal of any persisent storage on the filesystem)
- Asynchronous, long-running field processing including integration with external
	web-services including callbacks (with transcoding of video through Zencoder
	as an example usage)
- Copy-paste to move pages & pieces around within the site
- Undo
- Archive not delete, including restoration of deleted content
- Revert field to previous version
- Revert page to published version
- Scheduled publishing
- Allow for per-type additions to the user interface

#### Future

- Re-write the UI using web-components and ES6
- Back up the new UI with a full suite of integration tests


## Example

A Spontaneous site is composed of pages. Within those pages are zero or more 'Boxes'. Each of those Boxes can be configured to accept the addition of zero or more types of object. These object types can either be Pages -- creating a page hierarchy -- or Pieces that are displayed as the page's content.

A Spontaneous site is composed of a set of 'Pages', 'Boxes' and 'Pieces'. Each
'page' in the system maps to a webpage, accessible through a URL. Within that page are a set of Boxes, Pieces and sub-Pages that combine together to form its content.

To use a concrete example, imagine a page in a site dedicated to publishing recipes.

If you think about how you'd go about describing a recipe you might come up
with a list resembling the following:

- The title of the recipe
- A brief introduction to it telling you why you should cook it
- An image of the finished dish
- A list of ingredients. Each ingredient would have
	- A name
	- An amount (in grams, cups, whatever)
- A set of cooking steps. Each step consists of a description and perhaps an
	image

In a traditional CMS system most of the above would have to be constructed using
a rich-text editor. Using Spontaneous however you are able to map all of the
elements above into discrete editable blocks.

The recipe page would have the following fields:

- 'title' a simple unformatted string
- 'introduction' a piece of formatted text
- 'photo' an image of the finished dish

Along with these fields it would also have the following boxes:

- 'ingredients' this box will hold the list of ingredients. It is configured to
	allow the addition of any number of 'Ingredient' pieces. Each 'Ingredient'
	piece has 2 fields:
	- 'name' a simple string to hold the ingredient name
	- 'amount' another simple string to hold the amount needed

- 'steps' this box will hold the list of cooking steps involved in making the
	dish. It is configured to accept any number of 'Step' pieces. Each 'Step'
	piece has the following fields:
	- 'method' a rich text string describing the actual cooking step
	- 'image' an optional image showing the result of the step

In order to create a new recipe page the site editor simply needs to work
through the recipe adding the ingredients and steps needed and filling in their
details. At no point do they need to worry about the layout of the final page as
this will be completely handled by the CMS when the page is displayed.

The configuration of Spontaneous's 'schema' (the list of Page, Piece and Box
types needed to describe the site contents) is done using simple Ruby classes.
For instance, in order to describe the content types described above you would
need the following Ruby code:

    class RecipePage < Page
      field :title
      field :introduction, :richtext
      field :image

      box :ingredients do
        allow :Ingredient
      end

      box :steps do
        allow :Step
      end
    end

    class Ingredient < Piece
      field :name,   :string
      field :amount, :string
    end

    class Step < Piece
      field :method, :richtext
      field :image
    end

This will generate the following interface for the site editors:

<img src="https://github.com/SpontaneousCMS/spontaneous/raw/master/docs/recipe-interface-screenshot.png" alt="Spontaneous interface" width="800" height="577" />

## GETTING STARTED

**Install RVM**

		curl -L get.rvm.io | bash -s stable
		source ~/.rvm/scripts/'rvm'
		rvm requirements

**Install Ruby**

Spontaneous needs ruby >= 1.9.3 and Ruby >= 2.0 is preferred

		rvm install 2.1.1

**Install Spontaneous**

		gem install spontaneous

Now generate your site. Replace example.com with the domain of your site.

		spot create example.com
		cd example.com
		bundle install
		spot init
		spot server

and get started hacking the schema for your site...


