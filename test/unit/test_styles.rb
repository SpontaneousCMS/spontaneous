# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class StylesTest < MiniTest::Spec

  def teardown
    teardown_site
  end

  def setup
    @site = setup_site
    @template_root = File.expand_path(File.join(File.dirname(__FILE__), "../fixtures/styles"))
    @site.paths.add(:templates, @template_root)
    @renderer = S::Output::Template::PreviewRenderer.new
    S::Output.renderer = @renderer
  end

  context "styles for" do

    setup do
      ::Content.delete

      ::Page.box :box1

      class ::MissingClass < ::Piece; end
      class ::TemplateClass < ::Piece; end
      class ::TemplateSubClass1 < TemplateClass; end
      class ::TemplateSubClass2 < TemplateClass; end
      class ::InvisibleClass < ::Piece; end
    end

    teardown do
      ::Content.delete
      Object.send(:remove_const, :MissingClass) rescue nil
      Object.send(:remove_const, :TemplateClass) rescue nil
      Object.send(:remove_const, :TemplateSubClass1) rescue nil
      Object.send(:remove_const, :TemplateSubClass2) rescue nil
      Object.send(:remove_const, :InvisibleClass) rescue nil
    end

    context "pieces" do


      context "default styles" do
        setup do
          @page  = ::Page.new
          @piece = TemplateClass.new
          @page.box1 << @piece
        end

        should "return anonymous style if no templates are found" do
          piece = MissingClass.new
          piece.style.class.should == Spontaneous::Style::Default
          # piece.style.template.must_be_instance_of(Proc)
          piece.style.template.call.should == ""
        end

        should "derive path from owning class and name" do
          assert_correct_template(@piece, @template_root / 'template_class')
        end

        should "render using correct template" do
          @piece.render.should == "template_class.html.cut\n"
        end

        # should "be able to give a list of available formats" do
        #   skip("Need to re-implement the format functionality")
        #   @piece.style.formats.should == [:epub, :html, :pdf]
        # end

        should "simply render an empty string if no templates are available" do
          piece = InvisibleClass.new
          @page.box1 << piece
          piece.render.should == ""
        end
      end


      context "named styles" do
        setup do
          @page  = ::Page.new
          @piece = TemplateClass.new
          @page.box1 << @piece
        end

        should "use template found in class directory if exists" do
          TemplateClass.style :named1
          assert_correct_template(@piece, @template_root / 'template_class/named1')
          @piece.render.should == "template_class/named1.html.cut\n"
        end

        should "use template in template root with correct name if it exists" do
          TemplateClass.style :named2
          assert_correct_template(@piece, @template_root / 'named2')
          @piece.render.should == "named2.html.cut\n"
        end

        should "allow passing of directory/stylename" do
          TemplateClass.style :'orange/apple'
          # piece.style.template.should == 'orange/apple'
          assert_correct_template(@piece, @template_root / 'orange/apple')
          @piece.render.should == "orange/apple.html.cut\n"
        end

        should "default to styles marked as 'default'" do
          TemplateClass.style :named1
          TemplateClass.style :named2, :default => true
          assert_correct_template(@piece, @template_root / 'named2')
          # @piece.style.template.should == 'named2'
          @piece.render.should == "named2.html.cut\n"
        end
      end

      context "switching styles" do
        setup do
          TemplateClass.style :named1
          TemplateClass.style :named2, :default => true
          @page  = ::Page.new
          @piece = TemplateClass.new
          @page.box1 << @piece
          assert_correct_template(@piece, @template_root / 'named2')
          # @piece.style.template.should == 'named2'
          @piece.render.should == "named2.html.cut\n"
        end

        should "be possible" do
          @piece.style = :named1
          assert_correct_template(@piece, @template_root / 'template_class/named1')
          @piece.render.should == "template_class/named1.html.cut\n"
        end

        should "persist" do
          @piece.style = :named1
          @piece.save
          @piece = Content[@piece.id]
          # @piece.style.template.should == 'template_class/named1'
          assert_correct_template(@piece, @template_root / 'template_class/named1')
        end
      end

      context "inheriting styles" do
        should "use default for sub class if it exists" do
          piece = TemplateSubClass1.new
          assert_correct_template(piece, @template_root / 'template_sub_class1')
        end

        should "fall back to default style for superclass if default for class doesn't exist" do
          piece = TemplateSubClass2.new
          assert_correct_template(piece, @template_root / 'template_class')
          # piece.style.template.should == 'template_class'
        end
        should "fall back to defined default style for superclass if default for class doesn't exist" do
          TemplateClass.style :named1
          piece = TemplateSubClass2.new
          # piece.style.template.should == 'template_class/named1'
          assert_correct_template(piece, @template_root / 'template_class/named1')
        end
      end




      # context "inline templates" do
      #   setup do
      #     @class = Class.new(Content)
      #   end
      #   should "be definiable" do
      #     @class.style :simple
      #     @class.styles.length.should == 1
      #     t = @class.styles.first
      #     t.name.should == :simple
      #   end

      #   should "have configurable filenames" do
      #     @class.style :simple, :filename => "funky"
      #     t = @class.styles.first
      #     t.filename.should == "funky.html.cut"
      #   end

      #   should "have sane default titles" do
      #     @class.style :simple_style
      #     t = @class.styles.first
      #     t.title.should == "Simple Style"
      #   end

      #   should "have configurable titles" do
      #     @class.style :simple, :title => "A Simple Style"
      #     t = @class.styles.first
      #     t.title.should == "A Simple Style"
      #   end

      #   should "be accessable by name" do
      #     @class.style :simple
      #     @class.style :complex
      #     @class.styles[:simple].should == @class.styles.first
      #   end

      #   should "have #styles as a shortcut for #inliine_styles" do
      #     @class.style :simple
      #     @class.styles.should == @class.styles
      #   end

      #   should "take the first style as the default" do
      #     @class.style :simple
      #     @class.style :complex
      #     @class.styles.default.should == @class.styles[:simple]
      #   end

      #   should "honour the :default flag" do
      #     @class.style :simple
      #     @class.style :complex, :default => true
      #     @class.styles.default.should == @class.styles[:complex]
      #   end
      # end

      # context "assigned styles" do
      #   setup do
      #     class ::StyleTestClass < Content
      #       style :first_style
      #       style :default_style, :default => true
      #     end

      #     @a = StyleTestClass.new
      #     @b = StyleTestClass.new
      #     @a << @b
      #   end

      #   teardown do
      #     Object.send(:remove_const, :StyleTestClass)
      #   end

      #   should "assign the default style" do
      #     @a.pieces.first.style.should == ::StyleTestClass.styles.default
      #   end

      #   should "persist" do
      #     @a.save
      #     @b.save
      #     @a = StyleTestClass[@a.id]
      #     @a.pieces.first.style.should == ::StyleTestClass.styles.default
      #   end

      #   should "be settable" do
      #     @a.pieces.first.style = StyleTestClass.styles[:first_style]
      #     @a.save
      #     @a = StyleTestClass[@a.id]
      #     @a.pieces.first.style.should == ::StyleTestClass.styles[:first_style]
      #   end

      #   context "direct piece access" do
      #     setup do
      #       @a.pieces.first.style = StyleTestClass.styles[:first_style]
      #       @a.save
      #       piece_id = @a.pieces.first.target.id
      #       @piece = StyleTestClass[piece_id]
      #     end

      #     should "be accessible directly for pieces" do
      #       @piece.style.should == ::StyleTestClass.styles[:first_style]
      #     end

      #     should "not be settable directly on bare pieces" do
      #       lambda { @piece.style = ::StyleTestClass.styles.default }.must_raise(NoMethodError)
      #     end
      #   end
      # end

      context "inline templates" do
        setup do
          Page.add_output :pdf
          class ::InlineTemplateClass < Piece
            field :title

            template 'html: {{title}}'
            template :pdf, 'pdf: {{title}}'
          end

          @page = ::Page.new
          @a = InlineTemplateClass.new
          @page.box1 << @a
          @a.title = "Total Title"
        end

        teardown do
          Object.send(:remove_const, :InlineTemplateClass) rescue nil
        end

        should "be used to render the content" do
          @a.render.should ==  "html: Total Title"
        end

        should "be used to render the content with the right format" do
          @a.render(:pdf).should ==  "pdf: Total Title"
        end
      end

      # context "default styles" do
      #   class ::DefaultStyleClass < Spontaneous::Box
      #     field :title
      #   end

      #   class ::WithDefaultStyleClass < Content
      #     field :title
      #   end
      #   class ::WithoutDefaultStyleClass < Content
      #     field :title
      #     box :with_style, :type => :DefaultStyleClass
      #   end
      #   setup do
      #     Content.delete

      #     @with_default_style = WithDefaultStyleClass.new
      #     @with_default_style.title = "Total Title"
      #     @without_default_style = WithoutDefaultStyleClass.new
      #     @without_default_style.title = "No Title"
      #     @without_default_style.with_style.title = "Box Title"
      #     # @without_default_style.with_style.path = "Box Title"
      #   end

      #   teardown do
      #     Content.delete
      #     # Object.send(:remove_const, :DefaultStyleClass)
      #     # Object.send(:remove_const, :WithDefaultStyleClass)
      #     # Object.send(:remove_const, :WithoutDefaultStyleClass)
      #   end

      #   should "be used when available" do
      #     @with_default_style.render.should == "Title: Total Title\\n"
      #   end

      #   should "be used by boxes too" do
      #     @without_default_style.with_style.render.should == "Title: Box Title\\n"
      #   end

      #   should "fallback to anonymous style when default style template doesn't exist" do
      #     @without_default_style.render.should == "Title: Box Title\\n"
      #   end
      # end
    end

    context "boxes" do
      setup do
        class ::BoxA < ::Box; end
        class ::BoxB < ::Box; end
      end

      teardown do
        Object.send(:remove_const, :BoxA) rescue nil
        Object.send(:remove_const, :BoxB) rescue nil
      end

      context "anonymous boxes" do
        setup do
          TemplateClass.box :results
          TemplateClass.box :entities
          @page  = ::Page.new
          @piece = TemplateClass.new
          @page.box1 << @piece
        end

        should "use template with their name inside container class template dir if it exists" do
          @piece.results << TemplateClass.new
          assert_correct_template(@piece.results, @template_root / 'template_class/results')
          @piece.results.render.should == "template_class/results.html.cut\n"
        end

        should "render a simple list of content if named template doesn't exist" do
          @piece.entities << TemplateClass.new
          @piece.entities << TemplateClass.new
          @piece.entities.render.should == "template_class.html.cut\n\ntemplate_class.html.cut\n"
          @piece.entities.style.template.call.should == '${ render_content }'
        end


        should "use a named template if given" do
          TemplateClass.box :things do
            style :named1
          end
          @piece = TemplateClass.new
          @page.box1 << @piece
          assert_correct_template(@piece.things, @template_root / 'template_class/named1')
          @piece.things.render.should == "template_class/named1.html.cut\n"

          TemplateClass.box :dongles do
            style :named2
          end
          @piece = TemplateClass.new
          @page.box1 << @piece
          assert_correct_template(@piece.dongles, @template_root / 'named2')
          @piece.dongles.render.should == "named2.html.cut\n"
        end

        should "use styles assigned in a subclass xxx" do
          ::TemplateSubClass = Class.new(TemplateClass)
          ::TemplateSubSubClass = Class.new(TemplateSubClass)

          TemplateSubClass.box :bananas
          TemplateSubClass.box :apples, :style => :apples
          TemplateSubClass.box :oranges do
            style :oranges
          end

          Dir.mktmpdir do |template_root|
            @site.paths.add(:templates, template_root / "templates")


            piece = TemplateSubSubClass.new
            @page.box1 << piece

            # make sure we're running in a 'virgin' template dir
            assert Proc === piece.bananas.template, "Expected Proc not #{piece.bananas.template}"


            [[piece.bananas, %w(template_sub_sub_class/bananas template_sub_class/bananas)],
             [piece.apples, %w(template_sub_sub_class/apples template_sub_class/apples apples)],
             [piece.oranges, %w(template_sub_sub_class/oranges template_sub_class/oranges oranges)]
            ].each do |box, test_templates|
              test_templates.each do |test_template|
                path = template_root / "templates" / test_template
                FileUtils.mkdir_p(File.dirname(path))
                FileUtils.touch(path + '.html.cut')

                assert_correct_template(box, template_root / "templates" / test_template)

                FileUtils.rm_r(template_root / "templates")
              end
            end
          end


          Object.send(:remove_const, :TemplateSubClass) rescue nil
          Object.send(:remove_const, :TemplateSubSubClass) rescue nil
        end
      end

      context "boxes with a specified class" do
        setup do
          TemplateClass.box :entities, :type => :BoxA
          TemplateClass.box :results, :type => :BoxB
          @page  = ::Page.new
          @piece = TemplateClass.new
          @page.box1 << @piece
        end

        should "use the box name template if it exists" do
          assert_correct_template(@piece.results, @template_root / 'template_class/results')
          @piece.results.render.should == "template_class/results.html.cut\n"
        end

        should "use the box classes default template if box name template is missing" do
          assert_correct_template(@piece.entities, @template_root / 'box_a')
          @piece.entities.render.should == "box_a.html.cut\n"
        end

        should "find templates for box subclasses with specified types defined in a supertype" do
          Object.send(:remove_const, :TemplateSubClass) rescue nil
          Object.send(:remove_const, :BoxASubclass) rescue nil
          class ::BoxASubclass < BoxA; end
          TemplateClass.box :lastly, :type => :BoxASubclass
          class ::TemplateSubClass < TemplateClass
          end
          piece = TemplateSubClass.new
          @page.box1 << piece
          assert_correct_template(piece.lastly, @template_root / 'box_a')
          Object.send(:remove_const, :BoxASubclass) rescue nil
          Object.send(:remove_const, :TemplateSubClass) rescue nil
        end

        context "with configured styles" do
          setup do
            BoxA.style :runny
            BoxA.style :walky
          end

          should "be configurable to use a specific style" do
            TemplateClass.box :sprinters, :type => :BoxA, :style => :runny
            TemplateClass.box :strollers, :type => :BoxA, :style => :walky
            page = ::Page.new
            piece = TemplateClass.new
            page.box1 << piece
            assert_correct_template(piece.strollers, @template_root / 'template_class/walky')
            assert_correct_template(piece.sprinters, @template_root / 'box_a/runny')
          end
        end
      end
    end
  end
end

