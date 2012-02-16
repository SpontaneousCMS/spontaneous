![Spontaneous CMS](https://github.com/SpontaneousCMS/spontaneous/raw/master/application/static/logo-400px-transparent.png)

Spontaneous is a revolutionary new content management system that brings the best of Ruby and the best of HTML5 together in one elegant package.

This is version 2 of an existing (closed source) CMS that has been in active production use for over 6 years. For more information about that, and to see the sites that it powers, please go to [magnetised's homepage](http://magnetised.info/spontaneous).

## INTRODUCTION

Spontaneous uses a powerful hierarchical system to organise your information. This breaks out of the bonds of the traditional "title, slug, text" model of CMS content and instead allows content authors to build complex, highly styled pages out of simple, easily editable blocks.

- Ruby 1.9
- Using classes instead of db for metadata
  - Versioning of metadata
  - Keeps the developer in the text editor
  - Simplifies the interface for the site editor
  - Clear separation of content from schema - changing the site metadata
  - Carefully thought out deployment/upgrade process
  - Interaction between code and db content kept to a bare minimum and separated from normal site editing functions (a 'developer view')
- Built to deliver fast sites
  - Pages render to static HTML if possible
  - Compression of JS & CSS assets
- Proper workflow
  - Save != publish
  - Site editors can make sweeping changes and then make them live together
- Multiple outputs
  - Publish the same content to multiple formats (e.g. HTML, RSS, ATOM, JSON, PDF\*, EPUB\*)
- Sophisticated user managment
  - Customisable per-site roles to determine visibility & editabilty of site content
  - Give specified users access to only specific parts of the site\*
- HTML5 goodness
  - Drag & drop
  - Resumable uploads
  - Responsive
  - Attractive
  - Simple
- Powerful hierarchical data
  - Layout is done by the templates not the editor
  - Frees you up to do intricate designs
  - Minimises the risk of breaking the site design (consistent branding)
- Custom, page based, controllers
  - Define custom actions on particular page types

\* Features currently only sketched out awaiting full implementation

### The Content Hierarchy

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

, meaning that as well as writing copy and selecting images
the person writing the page also has to spend a lot of effort on the layout of
the page.
each of which will be laid out
automatically into pre-defined templates, leaving the editor to concentra

The only difference between a 'page' and a 'piece' is that pages are directly
publicly accessible through a URL, whereas pieces are only visible within the
context of a page.


Each of the objects in the content hierarchy -- pages, boxes & pieces -- can
have zero or more fields. These are where the actual content of the site, such
as text or images, will be entered by the site editors.

Each
or 'piece' has zero or more 'boxes' defined. Each of those boxes can be
configured to accept the addition of zero or more types of page or piece


The creation of the various relationships is done using normal Ruby code. Every
element in the content hierarchy has an associated Ruby class which has
configuration information about the fields

## GETTING STARTED

RVM
Ruby 1.9
gem install spontaneous
spot create site.com
cd site.com
bundle install
spot init
spot server

