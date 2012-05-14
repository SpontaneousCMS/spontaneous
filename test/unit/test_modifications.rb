# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class ModificationsTest < MiniTest::Spec

  def setup
    @now = Time.now
    @site = setup_site
  end

  def teardown
    teardown_site
  end

  context "modifications" do
    setup do
      stub_time(@now)

      # DB.logger = Logger.new($stdout)
      Content.delete

      class Page < Spontaneous::Page
        field :title, :string, :default => "New Page"
        box :things
      end
      class Piece < Spontaneous::Piece
        box :things
      end

      @root = Page.create(:uid => "root")
      count = 0
      2.times do |i|
        c = Page.new(:uid => i)
        @root.things << c
        count += 1
        2.times do |j|
          d = Piece.new(:uid => "#{i}.#{j}")
          c.things << d
          count += 1
          2.times do |k|
            d.things << Page.new(:uid => "#{i}.#{j}.#{k}")
            d.save
            count += 1
          end
        end
        c.save
      end
      @root.save
    end

    teardown do
      ModificationsTest.send(:remove_const, :Page) rescue nil
      ModificationsTest.send(:remove_const, :Piece) rescue nil
      Content.delete
      DB.logger = nil
    end



    should "register creation date of all content" do
      c = Content.create
      c.created_at.to_i.should == @now.to_i
      page = Page.create
      page.created_at.to_i.should == @now.to_i
    end

    should "update modification date of page when page fields are updated" do
      now = @now + 100
      stub_time(now)
      c = Content.first
      (c.modified_at.to_i - @now.to_i).abs.should <= 1
      c.label = "changed"
      c.save
      (c.modified_at - now).abs.should <= 1
    end

    should "update page timestamps on modification of its box fields" do
      Page.box :with_fields do
        field :title
      end

      stub_time(@now+3600)
      page = Page.first :uid => "0"
      (page.modified_at.to_i - @now.to_i).abs.should <= 1
      page.with_fields.title.value = "updated"
      page.save.reload
      page.modified_at.to_i.should == @now.to_i + 3600
    end

    should "update page timestamps on modification of a piece" do
      stub_time(@now+3600)
      page = Page.first :uid => "0"
      (page.modified_at.to_i - @now.to_i).abs.should <= 1
      content = page.contents.first
      content.page.should == page
      content.label = "changed"
      content.save
      page.reload
      page.modified_at.to_i.should == @now.to_i + 3600
    end

    should "update page timestamps on modification of a piece's box fields" do
      Piece.box :with_fields do
        field :title
      end
      stub_time(@now+3600)
      page = Page.first :uid => "0"
      (page.modified_at.to_i - @now.to_i).abs.should <= 1
      content = page.contents.first

      content.with_fields.title.value = "updated"
      content.save
      page.reload
      page.modified_at.to_i.should == @now.to_i + 3600
    end

    should "update page timestamp on addition of piece" do
      stub_time(@now+3600)
      page = Page.first :uid => "0"
      content = Content[page.contents.first.id]
      content.things << Piece.new
      content.save
      content.modified_at.to_i.should == @now.to_i + 3600
      page.reload
      page.modified_at.to_i.should == @now.to_i + 3600
    end

    should "not update the parent page's timestamp on addition of a child page xxx" do
      stub_time(@now+1000)
      page = Page.first :uid => "0"
      page.things << Page.new
      page.save.reload
      page.modified_at.to_i.should == @now.to_i
    end

    should "update the parent page's modification time if child pages are re-ordered xxx" do
      page = Page.first :uid => "0.0.0"
      page.things << Page.new(:uid => "0.0.0.0")
      page.things << Page.new(:uid => "0.0.0.1")
      page.save
      page = Page.first :uid => "0.0.0"
      stub_time(@now+1000)
      child = page.things.first
      child.update_position(1)
      page.reload.modified_at.to_i.should == @now.to_i + 1000
    end

    should "update a page's timestamp on modification of its slug" do
      stub_time(@now+1000)
      page = Page.first :uid => "0"
      page.slug = "changed"
      page.save.reload
      page.modified_at.to_i.should == @now.to_i + 1000
    end

    should "not update child pages timestamps after changing their parent's slug" do
      page = Page.first :uid => "0.0.0"
      modified = page.modified_at.to_i
      stub_time(@now+1000)
      page = Page.first :uid => "0"
      page.slug = "changed"
      page.save.reload
      page.modified_at.to_i.should == @now.to_i + 1000
      page = Page.first :uid => "0.0.0"
      page.modified_at.to_i.should == modified
    end

    should "update the pages timestamp if a boxes order is changed" do
      stub_time(@now+3600)
      page = Page.first :uid => "0"
      content = Content[page.contents.first.id]
      content.update_position(1)
      page.reload.modified_at.to_i.should == @now.to_i + 3600
    end

    should "update the parent page's modification time if the contents of a piece's box are re-ordered" do
      stub_time(@now+3600)
      page = Page.first :uid => "0"
      content = page.things.first.things.first
      content.update_position(1)
      page.reload.modified_at.to_i.should == @now.to_i + 3600
    end

    should "update the parent page's modification date if a piece is deleted" do
      stub_time(@now+3600)
      page = Page.first :uid => "0"
      content = Content[page.contents.first.id]
      content.destroy
      page.reload.modified_at.to_i.should == @now.to_i + 3600
    end

    should "update the parent page's modification date if a page is deleted" do
      stub_time(@now+3600)
      page = Page.first :uid => "0"
      content = Content[page.things.first.things.first.id]
      content.destroy
      page.reload.modified_at.to_i.should == @now.to_i + 3600
    end

    should "add entry to the list of side effects for a visibility change" do
      stub_time(@now+3600)
      page = Page.first :uid => "1"
      old_slug = page.slug
      page.slug = "changed"
      page.save
      page.reload
      page.pending_modifications.length.should == 1
      mods = page.pending_modifications(:slug)
      mods.length.should == 1
      mod = mods.first
      mod.must_be_instance_of Spontaneous::Plugins::Modifications::SlugModification
      mod.old_value.should == old_slug
      mod.new_value.should == "changed"
      mod.created_at.to_i.should == @now.to_i + 3600
    end

    should "serialize page modifications" do
      stub_time(@now+3600)
      page = Page.first :uid => "1"
      page.slug = "changed"
      page.save
      page.pending_modifications.length.should == 1
      mod = page.pending_modifications(:slug).first
      page = Page.first :id => page.id
      page.pending_modifications.length.should == 1
      page.pending_modifications(:slug).first.should == mod
      page.pending_modifications(:slug).first.created_at.to_i.should == @now.to_i + 3600
    end

    should "concatenate multiple slug modifications together" do
      stub_time(@now+3600)
      page = Page.first :uid => "1"
      old_slug = page.slug
      page.slug = "changed"
      page.save
      page.pending_modifications.length.should == 1
      page.slug = "changed-again"
      page.save
      mod = page.pending_modifications(:slug).first
      mod.old_value.should == old_slug
      mod.new_value.should == "changed-again"
    end

    should "know the number of pages affected by slug modification" do
      stub_time(@now+3600)
      page = Page.first :uid => "1"
      page.slug = "changed"
      page.save
      mod = page.pending_modifications(:slug).first
      mod.count.should == 4
    end

    should "show the number of pages whose visibility is affected in the case of a visibility change" do
      stub_time(@now+3600)
      page = Page.first :uid => "1"
      page.hide!
      page.reload
      mods = page.pending_modifications(:visibility)
      mods.length.should == 1
      mod = mods.first
      mod.count.should == 4
      mod.owner.should == page
    end

    should "record visibility changes that originate from a content piece" do
      stub_time(@now+3600)
      page = Page.first :uid => "1"
      page.things.first.hide!
      page.reload
      mods = page.pending_modifications(:visibility)
      mods.length.should == 1
      mod = mods.first
      mod.count.should == 2
      mod.owner.should == page.things.first
    end

    should "show number of pages that are to be deleted in the case of a deletion" do
      stub_time(@now+3600)
      page = Page.first(:uid => "1")
      owner = page.owner
      page.destroy
      page = Page.first(:uid => "root")
      mods = page.pending_modifications(:deletion)
      mod = mods.first
      # count is number of children of deleted page + 1 (for deleted page)
      mod.count.should == 5
      mod.owner.should == owner.reload
    end

    should "show number of pages deleted if piece with pages is deleted" do
      stub_time(@now+3600)
      page = Page.first(:uid => "1")
      piece = page.things.first
      owner = piece.owner
      piece.destroy
      page = Page.first(:uid => "1")
      mods = page.pending_modifications(:deletion)
      mod = mods.first
      mod.count.should == 2
      mod.owner.should == owner.reload
    end

    should "show number of pages deleted if page belonging to piece is deleted" do
      stub_time(@now+3600)
      page = Page.first(:uid => "1")
      child = page.things.first.things.first
      owner = child.owner
      child.destroy
      page = Page.first(:uid => "1")
      mods = page.pending_modifications(:deletion)
      mod = mods.first
      mod.count.should == 1
      mod.owner.should == owner.reload
    end

    should "have an empty modification if the slug has been reverted to original value" do
      stub_time(@now+3600)
      page = Page.first :uid => "1"
      old_slug = page.slug
      page.slug = "changed"
      page.save
      page.pending_modifications.length.should == 1
      page.slug = "changed-again"
      page.save
      page.slug = old_slug
      page.save
      mods = page.reload.pending_modifications(:slug)
      mods.length.should == 0
    end

    should "have an empty modification if the visibility has been reverted to original value" do
      stub_time(@now+3600)
      page = Page.first :uid => "1"
      page.things.first.hide!
      page.reload
      page.things.first.show!
      page.reload
      mods = page.pending_modifications(:visibility)
      mods.length.should == 0
    end

    context "during publish" do
      setup do
        @initial_revision = 1
        @final_revision = 2
        Content.delete_revision(@initial_revision) rescue nil
        Content.delete_revision(@final_revision) rescue nil
        S::Content.publish(@initial_revision)
      end

      teardown do
        Content.delete_revision(@initial_revision) rescue nil
        Content.delete_revision(@final_revision) rescue nil
      end

      should "act on path change modifications" do
        page = Page.first :uid => "1"
        old_slug = page.slug
        page.slug = "changed"
        page.save
        S::Content.publish(@final_revision, [page.id])
        S::Content.with_revision(@final_revision) do
          %w(1 1.1.1).each do |uid|
            published_page = Page.first :uid => uid
            S::Content.with_editable do
              editable_page = Page.first :uid => uid
              published_page.path.should == editable_page.path
            end
          end
        end
      end

      should "not publish slug changes on pages other than the one being published" do
        #/bands/beatles -> /bands/beatles-changed
        #/bands -> /bands-changed
        # publish(bands)
        # with_published { beatles.path.should == /bands-changed/beatles }
        page = Page.first :uid => "1"
        page.slug = "changed"
        page.save

        child_page = Page.first :uid => "1.0.0"
        old_slug = child_page.slug
        child_page.slug = "changed-too"
        child_page.save

        S::Content.publish(@final_revision, [page.id])
        S::Content.with_revision(@final_revision) do
          published = Page.first :uid => "1.0.0"
          published.path.should == "/changed/#{old_slug}"
        end
      end

      should "publish the correct path for new child pages with an un-published parent slug change" do
        # add /bands/beatles
        # /bands -> /bands-changed
        # publish(beatles)
        # with_published { beatles.path.should == /bands/beatles }
        page = Page.first :uid => "1"
        old_slug = page.slug
        page.slug = "changed"
        page.save

        child_page = Page.first :uid => "1.0.0"
        child_page.slug = "changed-too"
        child_page.save

        S::Content.publish(@final_revision, [child_page.id])
        S::Content.with_revision(@final_revision) do
          published = Page.first :uid => "1.0.0"
          published.path.should == "/#{old_slug}/changed-too"
        end
      end


      should "act on visibility modifications" do
        page = Page.first :uid => "1"
        page.hide!
        S::Content.publish(@final_revision, [page.id])
        S::Content.with_revision(@final_revision) do
          %w(1 1.1.1).each do |uid|
            published_page = Page.first :uid => uid
            S::Content.with_editable do
              editable_page = Page.first :uid => uid
              published_page.hidden?.should == editable_page.hidden?
            end
          end
        end
      end

      should "publish the correct visibility for new child pages with un-published up-tree visibility changes" do
        page = Page.first :uid => "1"
        page.hide!

        child_page = Page.new :uid => "child"
        page.things << child_page
        page.save

        S::Content.publish(@final_revision, [child_page.id])

        S::Content.with_revision(@final_revision) do
          published = Page.first :uid => "1.0.0"
          published.visible?.should be_true
          published = Page.first :uid => "child"
          published.visible?.should be_true
        end
      end

      should "publish the correct visibility for new child pages with published up-tree visibility changes" do
        page = Page.first :uid => "1"
        page.hide!

        child_page = Page.new :uid => "child"
        page.things << child_page
        page.save

        S::Content.publish(@final_revision, [page.id, child_page.id])

        S::Content.with_revision(@final_revision) do
          published = Page.first :uid => "child"
          published.visible?.should be_false
        end
      end

      should "publish the correct visibility for child pages with un-published parent visibility changes" do
        # if we publish changes to a child page whose parent page is hidden but that visibility change
        # hasn't been published then the child page should be visible until the parent is published
        page = Page.first :uid => "1"
        page.hide!

        child_page = Page.first :uid => "1.0.0"
        child_page.slug = "changed-too"
        child_page.save

        S::Content.publish(@final_revision, [child_page.id])

        S::Content.with_revision(@final_revision) do
          published = Page.first :uid => "1.0.0"
          published.visible?.should be_true
        end
      end

      should "act on multiple modifications" do
        page = Page.first :uid => "1"
        page.slug = "changed"
        page.slug = "changed-again"
        page.hide!

        S::Content.publish(@final_revision, [page.id])
        S::Content.with_revision(@final_revision) do
          %w(1 1.1.1).each do |uid|
            published_page = Page.first :uid => uid
            S::Content.with_editable do
              editable_page = Page.first :uid => uid
              published_page.hidden?.should == editable_page.hidden?
              published_page.slug.should == editable_page.slug
              published_page.path.should == editable_page.path
            end
          end
        end
      end

      should "ignore deletion modifications" do
        page = Page.first(:uid => "1")
        page.destroy
        page = Page.first(:uid => "root")
        S::Content.publish(@final_revision, [page.id])
        S::Content.with_revision(@final_revision) do
          %w(1 1.1.1).each do |uid|
            published_page = Page.first :uid => uid
            published_page.should be_nil
          end
          published_page = Page.first :uid => "0"
          published_page.should_not be_nil
        end
      end

      should "clear modifications after publish" do
        page = Page.first :uid => "1"
        page.slug = "changed"
        page.hide!
        S::Content.publish(@final_revision, [page.id])
        page = Page.first :id => page.id
        page.pending_modifications.length.should == 0
      end
    end

    context "with assigned editor" do
      setup do
        Spontaneous::Permissions::User.delete
        @user = Spontaneous::Permissions::User.create(:email => "root@example.com", :login => "root", :name => "root", :password => "rootpass", :password_confirmation => "rootpass")
      end

      teardown do
        @user.destroy
      end

      should "add the editor to any modifications" do
        stub_time(@now+3600)
        page = Page.first :uid => "1"
        page.current_editor = @user
        page.slug = "changed"
        page.save
        mod = page.pending_modifications(:slug).first
        mod.user.should == @user
      end

      should "persist the user" do
        stub_time(@now+3600)
        page = Page.first :uid => "1"
        page.current_editor = @user
        page.slug = "changed"
        page.save
        page = Page.first :uid => "1"
        mod = page.pending_modifications(:slug).first
        mod.user.should == @user
      end
    end
  end
end
