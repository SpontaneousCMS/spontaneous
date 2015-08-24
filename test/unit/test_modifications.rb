# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


describe "Modifications" do

  before do
    @now = Time.now
    @site = setup_site
    Timecop.freeze(@now)

    Content.delete

    class ::Page
      field :title, :string, default: "New Page"
      box :things
    end
    class ::Piece
      box :things
    end

    Content.scope(nil, false) do
      @root = Page.create(uid: "root")
      count = 0
      2.times do |i|
        c = Page.new(uid: i, slug: "p-#{i}")
        @root.things << c
        count += 1
        2.times do |j|
          d = Piece.new(uid: "#{i}.#{j}", slug: "p-#{i}-#{j}")
          c.things << d
          count += 1
          2.times do |k|
            d.things << Page.new(uid: "#{i}.#{j}.#{k}", slug: "p-#{i}-#{j}-#{k}")
            d.save
            count += 1
          end
        end
        c.save
      end
    end
    @root.save
  end

  after do
    Timecop.return
    Object.send(:remove_const, :Page) rescue nil
    Object.send(:remove_const, :Piece) rescue nil
    Content.delete
    teardown_site
  end

  it "register creation date of all content" do
    c = Content.create
    (c.created_at - @now).must_be :<=, 1
    page = Page.create
    (page.created_at - @now).must_be :<=, 1
  end

  it "update modification date of page when page fields are updated" do
    now = @now + 100
    Timecop.freeze(now) do
      c = Page.first
      (c.modified_at.to_i - @now.to_i).abs.must_be :<=, 1
      c.update(title: "changed")
      (c.modified_at - now).abs.must_be :<=, 1
    end
  end

  it "update modification date of path when page visibility is changed" do
    now = @now + 100
    Timecop.freeze(now) do
      c = Page.uid("0")
      (c.modified_at.to_i - @now.to_i).abs.must_be :<=, 1
      c.toggle_visibility!
      (c.modified_at - now).abs.must_be :<=, 1
    end
  end

  it "update page timestamps on modification of its box fields" do
    Page.box :with_fields do
      field :title
    end

    Timecop.freeze(@now+3600) do
      page = Page.first uid: "0"
      (page.modified_at.to_i - @now.to_i).abs.must_be :<=, 1
      page.with_fields.title.value = "updated"
      page.save.reload
      page.modified_at.to_i.must_equal @now.to_i + 3600
    end
  end

  it "update page timestamps on modification of a piece" do
    Timecop.freeze(@now+3600) do
      page = Page.first uid: "0"
      (page.modified_at.to_i - @now.to_i).abs.must_be :<=, 1
      content = page.contents.first
      content.page.must_equal page
      content.label = "changed"
      content.save
      page.reload
      page.modified_at.to_i.must_equal @now.to_i + 3600
    end
  end

  it "update page timestamps on modification of a piece's box fields" do
    Piece.box :with_fields do
      field :title
    end
    Timecop.freeze(@now+3600) do
      page = Page.first uid: "0"
      (page.modified_at.to_i - @now.to_i).abs.must_be :<=, 1
      content = page.contents.first

      content.with_fields.title.value = "updated"
      content.save
      page.reload
      page.modified_at.to_i.must_equal @now.to_i + 3600
    end
  end

  it "update page timestamp on addition of piece" do
    Timecop.freeze(@now + 3600) do
      page = Page.first uid: "0"
      content = Content[page.contents.first.id]
      content.things << Piece.new
      content.save
      content.modified_at.to_i.must_equal @now.to_i + 3600
      page.reload
      page.modified_at.to_i.must_equal @now.to_i + 3600
    end
  end

  it "update the parent page's modification time if child pages are re-ordered" do
    page = Page.first uid: "0.0.0"
    page.things << Page.new(uid: "0.0.0.0")
    page.things << Page.new(uid: "0.0.0.1")
    page.save
    page = Page.first uid: "0.0.0"
    Timecop.freeze(@now + 1000) do
      child = page.things.first
      child.update_position(1)
      page.reload.modified_at.to_i.must_equal @now.to_i + 1000
    end
  end

  it "update a page's timestamp on modification of its slug" do
    Timecop.freeze(@now + 1000) do
      page = Page.first uid: "0"
      page.slug = "changed"
      page.save.reload
      page.modified_at.to_i.must_equal @now.to_i + 1000
    end
  end

  it "update the pages timestamp if a boxes order is changed" do
    Timecop.freeze(@now+3600) do
      page = Page.first uid: "0"
      content = Content[page.contents.first.id]
      content.update_position(1)
      page.reload.modified_at.to_i.must_equal @now.to_i + 3600
    end
  end

  it "update the parent page's modification time if the contents of a piece's box are re-ordered" do
    Timecop.freeze(@now+3600) do
      page = Page.first uid: "0"
      content = page.things.first.things.first
      content.update_position(1)
      page.reload.modified_at.to_i.must_equal @now.to_i + 3600
    end
  end

  it "update the parent page's modification date if a piece is deleted" do
    Timecop.freeze(@now+3600) do
      page = Page.first uid: "0"
      content = Content[page.contents.first.id]
      content.destroy
      page.reload.modified_at.to_i.must_equal @now.to_i + 3600
    end
  end

  it "update the parent page's modification date if a page is deleted" do
    Timecop.freeze(@now+3600) do
      page = Page.first uid: "0"
      content = Content[page.things.first.things.first.id]
      content.destroy
      page.reload.modified_at.to_i.must_equal @now.to_i + 3600
    end
  end

  it "add entry to the list of side effects for a visibility change" do
    Timecop.freeze(@now+3600) do
      page = Page.first uid: "1"
      old_slug = page.slug
      page.slug = "changed"
      page.save
      page.reload
      page.pending_modifications.length.must_equal 1
      mods = page.pending_modifications(:slug)
      mods.length.must_equal 1
      mod = mods.first
      mod.must_be_instance_of Spontaneous::Model::Core::Modifications::SlugModification
      mod.old_value.must_equal old_slug
      mod.new_value.must_equal "changed"
      mod.created_at.to_i.must_equal @now.to_i + 3600
    end
  end

  it "adds an entry to the list of side effects for an ownership change" do
    Timecop.freeze(@now+3600) do
      new_owner = Page.first uid: "1"
      page = Page.first uid: "1.1.1"
      old_owner_id = page.visibility_path
      new_owner.things.adopt(page)
      page.save
      page.reload
      page.pending_modifications.length.must_equal 1
      mods = page.pending_modifications(:owner)
      mods.length.must_equal 1
      mod = mods.first
      mod.must_be_instance_of Spontaneous::Model::Core::Modifications::OwnerModification
      mod.old_value.must_equal old_owner_id
      mod.new_value.must_equal new_owner.id
      mod.created_at.to_i.must_equal @now.to_i + 3600
    end
  end

  it "only adds a single ownership modification entry" do
    Timecop.freeze(@now+3600) do
      new_owner = Page.first uid: "1"
      page = Page.first uid: "1.1.1"
      old_owner_id = page.visibility_path
      new_owner.things.adopt(page)
      @root.things.adopt(page)
      page.save
      page.reload
      page.pending_modifications.length.must_equal 1
      mods = page.pending_modifications(:owner)
      mods.length.must_equal 1
      mod = mods.first
      mod.must_be_instance_of Spontaneous::Model::Core::Modifications::OwnerModification
      mod.old_value.must_equal old_owner_id
      mod.new_value.must_equal @root.id
      mod.created_at.to_i.must_equal @now.to_i + 3600
    end
  end

  it "removes ownership changes if the ownership reverts" do
    Timecop.freeze(@now+3600) do
      new_owner = Page.first uid: "1"
      page = Page.first uid: "1.1.1"
      old_owner = page.owner
      new_owner.things.adopt(page)
      old_owner.things.adopt(page)
      page.save
      page.reload
      page.pending_modifications.length.must_equal 0
    end
  end

  it "show the number of affected content entries in the case of an ownership change" do
    Timecop.freeze(@now+3600) do
      new_owner = Page.first uid: "root"
      page = Piece.first uid: "1.1"
      new_owner.things.adopt(page)
      page.save
      page.reload
      mod = page.pending_modifications(:owner).first
      mod.count.must_equal 2
    end
  end

  it "serialize page modifications" do
    Timecop.freeze(@now+3600) do
      page = Page.first uid: "1"
      page.slug = "changed"
      page.save
      page.pending_modifications.length.must_equal 1
      mod = page.pending_modifications(:slug).first
      page = Page.first id: page.id
      page.pending_modifications.length.must_equal 1
      page.pending_modifications(:slug).first.must_equal mod
      page.pending_modifications(:slug).first.created_at.to_i.must_equal @now.to_i + 3600
    end
  end

  it "concatenate multiple slug modifications together" do
    Timecop.freeze(@now+3600) do
      page = Page.first uid: "1"
      old_slug = page.slug
      page.slug = "changed"
      page.save
      page.pending_modifications.length.must_equal 1
      page.slug = "changed-again"
      page.save
      mod = page.pending_modifications(:slug).first
      mod.old_value.must_equal old_slug
      mod.new_value.must_equal "changed-again"
    end
  end

  it "know the number of pages affected by slug modification" do
    Timecop.freeze(@now+3600) do
      page = Page.first uid: "1"
      page.slug = "changed"
      page.save
      mod = page.pending_modifications(:slug).first
      mod.count.must_equal 4
    end
  end

  it "show the number of pages whose visibility is affected in the case of a visibility change" do
    Timecop.freeze(@now+3600) do
      page = Page.first uid: "1"
      page.hide!
      page.reload
      mods = page.pending_modifications(:visibility)
      mods.length.must_equal 1
      mod = mods.first
      mod.count.must_equal 4
      mod.owner.must_equal page
    end
  end

  it "record visibility changes that originate from a content piece" do
    Timecop.freeze(@now+3600) do
      page = Page.first uid: "1"
      page.things.first.hide!
      page.reload
      mods = page.pending_modifications(:visibility)
      mods.length.must_equal 1
      mod = mods.first
      mod.count.must_equal 2
      mod.owner.must_equal page.things.first
    end
  end

  it "show number of pages that are to be deleted in the case of a deletion" do
    Timecop.freeze(@now+3600) do
      page = Page.first(uid: "1")
      owner = page.owner
      page.destroy
      page = Page.first(uid: "root")
      mods = page.pending_modifications(:deletion)
      mod = mods.first
      # count is number of children of deleted page + 1 (for deleted page)
      mod.count.must_equal 5
      mod.owner.must_equal owner.reload
    end
  end

  it "show number of pages deleted if piece with pages is deleted" do
    Timecop.freeze(@now+3600) do
      page = Page.first(uid: "1")
      piece = page.things.first
      owner = piece.owner
      piece.destroy
      page = Page.first(uid: "1")
      mods = page.pending_modifications(:deletion)
      mod = mods.first
      mod.count.must_equal 2
      mod.owner.must_equal owner.reload
    end
  end

  it "show number of pages deleted if page belonging to piece is deleted" do
    Timecop.freeze(@now+3600) do
      page = Page.first(uid: "1")
      child = page.things.first.things.first
      owner = child.owner
      child.destroy
      page = Page.first(uid: "1")
      mods = page.pending_modifications(:deletion)
      mod = mods.first
      mod.count.must_equal 1
      mod.owner.must_equal owner.reload
    end
  end

  it "have an empty modification if the slug has been reverted to original value" do
    Timecop.freeze(@now+3600) do
      page = Page.first uid: "1"
      old_slug = page.slug
      page.slug = "changed"
      page.save
      page.pending_modifications.length.must_equal 1
      page.slug = "changed-again"
      page.save
      page.slug = old_slug
      page.save
      mods = page.reload.pending_modifications(:slug)
      mods.length.must_equal 0
    end
  end

  it "have an empty modification if the visibility has been reverted to original value" do
    Timecop.freeze(@now+3600) do
      page = Page.first uid: "1"
      page.things.first.hide!
      page.reload
      page.things.first.show!
      page.reload
      mods = page.pending_modifications(:visibility)
      mods.length.must_equal 0
    end
  end

  describe "during publish" do
    before do
      @initial_revision = 1
      @final_revision = 2
      Content.delete_revision(@initial_revision) rescue nil
      Content.delete_revision(@final_revision) rescue nil
      ::Content.publish(@initial_revision)
    end

    after do
      Content.delete_revision(@initial_revision) rescue nil
      Content.delete_revision(@final_revision) rescue nil
      Content.delete_revision(@final_revision+1) rescue nil
    end

    it "act on path change modifications" do
      page = Page.first uid: "1"
      page.slug = "changed"
      page.save
      ::Content.publish(@final_revision, [page.id])
      ::Content.with_revision(@final_revision) do
        %w(1 1.1.1).each do |uid|
          published_page = Page.first uid: uid
          ::Content.with_editable do
            editable_page = Page.first uid: uid
            published_page.path.must_equal editable_page.path
          end
        end
      end
    end

    it "not publish slug changes on pages other than the one being published" do
      #/bands/beatles -> /bands/beatles-changed
      #/bands -> /bands-changed
      # publish(bands)
      # with_published { beatles.path.must_equal /bands-changed/beatles }
      page = Page.first uid: "1"
      page.slug = "changed"
      page.save

      child_page = Page.first uid: "1.0.0"
      old_slug = child_page.slug
      child_page.slug = "changed-too"
      child_page.save
      ::Content.publish(@final_revision, [page.id])
      ::Content.with_revision(@final_revision) do
        published = Page.first uid: "1.0.0"
        published.path.must_equal "/changed/#{old_slug}"
      end
    end

    it "publish the correct path for new child pages with an un-published parent slug change" do
      # add /bands/beatles
      # /bands -> /bands-changed
      # publish(beatles)
      # with_published { beatles.path.must_equal /bands/beatles }
      page = Page.first uid: "1"
      old_slug = page.slug
      page.slug = "changed"
      page.save

      child_page = Page.first uid: "1.0.0"
      child_page.slug = "changed-too"
      child_page.save

      ::Content.publish(@final_revision, [child_page.id])
      ::Content.with_revision(@final_revision) do
        published = Page.first uid: "1.0.0"
        published.path.must_equal "/#{old_slug}/changed-too"
      end
    end


    it "act on visibility modifications" do
      page = Page.first uid: "1"
      page.hide!
      ::Content.publish(@final_revision, [page.id])
      ::Content.with_revision(@final_revision) do
        %w(1 1.1.1).each do |uid|
          published_page = Page.first uid: uid
          ::Content.with_editable do
            editable_page = Page.first uid: uid
            published_page.hidden?.must_equal editable_page.hidden?
          end
        end
      end
    end

    it "publish the correct visibility for new child pages with un-published up-tree visibility changes" do
      page = Page.first uid: "1"
      page.hide!

      child_page = Page.new uid: "child"
      page.things << child_page
      page.save

      ::Content.publish(@final_revision, [child_page.id])

      ::Content.with_revision(@final_revision) do
        published = Page.first uid: "1.0.0"
        assert published.visible?
        published = Page.first uid: "child"
        assert published.visible?
      end
    end

    it "publish the correct visibility for new child pages with published up-tree visibility changes" do
      page = Page.first uid: "1"
      page.hide!

      child_page = Page.new uid: "child"
      page.things << child_page
      page.save

      ::Content.publish(@final_revision, [page.id, child_page.id])

      ::Content.with_revision(@final_revision) do
        published = Page.first uid: "child"
        refute published.visible?
      end
    end

    it "publish the correct visibility for child pages with un-published parent visibility changes" do
      # if we publish changes to a child page whose parent page is hidden but that visibility change
      # hasn't been published then the child page it be visible until the parent is published
      page = Page.first uid: "1"
      page.hide!

      child_page = Page.first uid: "1.0.0"
      child_page.slug = "changed-too"
      child_page.save

      ::Content.publish(@final_revision, [child_page.id])

      ::Content.with_revision(@final_revision) do
        published = Page.first uid: "1.0.0"
        assert published.visible?
      end
    end

    it "publish the correct visibility for immediate child pages with published parent visibility changes" do
      page = Page.first uid: "1"

      child_page = Page.new uid: "newpage"
      page.things << child_page
      page.save

      ::Content.publish(@final_revision, [page.id, child_page.id])

      refute child_page.hidden?

      page.hide!

      assert child_page.reload.hidden?

      ::Content.publish(@final_revision + 1, [page.id])

      ::Content.with_revision(@final_revision + 1) do
        published = Page.first uid: "newpage"
        refute published.visible?
      end
    end

    it "publish the correct visibility for child pages with published parent visibility changes" do
      page = Page.first uid: "1"
      child_page = Page.first uid: "1.0.0"
      refute child_page.hidden?

      page.hide!

      assert child_page.reload.hidden?

      ::Content.publish(@final_revision, [page.id])

      ::Content.with_revision(@final_revision) do
        published = Page.first uid: "1.0.0"
        refute published.visible?
      end
    end

    it "maintain correct published visibility for pieces" do
      page = Page.first uid: "1"
      piece = page.things.first
      piece.hide!
      ::Content.publish(@final_revision, [page.id])
      ::Content.with_revision(@final_revision) do
        piece = Page.first(uid: "1").things.first
        refute piece.visible?
      end

      ::Content.publish(@final_revision+1, [page.id])

      ::Content.with_revision(@final_revision+1) do
        piece = Page.first(uid: "1").things.first
        refute piece.visible?
      end
    end

    it "maintain correct published visibility for pages" do
      page = Page.first uid: "1.1.1"
      page.hide!
      ::Content.publish(@final_revision, [page.id])
      ::Content.with_revision(@final_revision) do
        page = Page.first(uid: "1.1.1")
        refute page.visible?
      end

      ::Content.publish(@final_revision+1, [page.id])

      ::Content.with_revision(@final_revision+1) do
        page = Page.first(uid: "1.1.1")
        refute page.visible?
      end
    end

    it 'relocates dependent content after an ownership change' do
      new_owner = Page.first uid: "root"
      piece = Piece.first uid: "1.1"
      deep = Content.first uid: '1.1.1'
      child = deep.things << Piece.new(uid: '1.1.1.0')
      new_owner.things.adopt(piece)
      ::Content.publish(@final_revision, [deep.id])
      expected_visibility_paths = piece.reload.contents.map(&:visibility_path)
      ids = piece.contents.map(&:id)
      piece.save

      child_visibility_path = child.reload.visibility_path
      ::Content.publish(@final_revision+1, [piece.id])
      ::Content.with_revision(@final_revision+1) do
        published_piece = ::Content.first(id: piece.id)
        published_piece.contents.map(&:visibility_path).must_equal expected_visibility_paths
        published_child = ::Content.first(id: child.id)
        published_child.visibility_path.must_equal child_visibility_path
      end
    end

    it "act on multiple modifications" do
      page = Page.first uid: "1"
      page.slug = "changed"
      page.slug = "changed-again"
      page.hide!

      ::Content.publish(@final_revision, [page.id])
      ::Content.with_revision(@final_revision) do
        %w(1 1.1.1).each do |uid|
          published_page = Page.first uid: uid
          ::Content.with_editable do
            editable_page = Page.first uid: uid
            published_page.hidden?.must_equal editable_page.hidden?
            published_page.slug.must_equal editable_page.slug
            published_page.path.must_equal editable_page.path
          end
        end
      end
    end

    it "ignore deletion modifications" do
      page = Page.first(uid: "1")
      page.destroy
      page = Page.first(uid: "root")
      ::Content.publish(@final_revision, [page.id])
      ::Content.with_revision(@final_revision) do
        %w(1 1.1.1).each do |uid|
          published_page = Page.first uid: uid
          published_page.must_be_nil
        end
        published_page = Page.first uid: "0"
        published_page.wont_be_nil
      end
    end

    it "clear modifications after publish" do
      page = Page.first uid: "1"
      page.slug = "changed"
      page.hide!
      ::Content.publish(@final_revision, [page.id])
      page = Page.first id: page.id
      page.pending_modifications.length.must_equal 0
    end

    it "clear modifications after publish all" do
      page = Page.first uid: "1"
      page.slug = "changed"
      page.hide!
      ::Content.publish(@final_revision, nil)
      page = Page.first id: page.id
      page.pending_modifications.length.must_equal 0
    end

    describe 'path history' do
      after do
        Spontaneous::PagePathHistory.delete
      end

      it "doesn't insert a path history entry in edit mode" do
        page = Page.first uid: "1"
        old_path = page.path
        page.slug = "changed"
        page.save
        history = page.reload.path_history
        history.length.must_equal 0
      end

      it 'inserts a path history entry when page path changes' do
        page = Page.first uid: "1"
        old_path = page.path
        page.slug = "changed"
        page.save
        ::Content.publish(@final_revision, [page.id])
        history = page.reload.path_history
        history.length.must_equal 1
        path = history.first
        path.path.must_equal old_path
        path.revision.must_equal @final_revision
      end

      it 'inserts a path history entry when publishing all changes' do
        page = Page.first uid: "1"
        old_path = page.path
        page.slug = "changed"
        page.save
        ::Content.publish(@final_revision, nil)
        history = page.reload.path_history
        history.length.must_equal 1
        path = history.first
        path.path.must_equal old_path
        path.revision.must_equal @final_revision
      end

      it 'inserts a path history entry for every affected child page' do
        page = Page.first uid: "1"
        old_path = page.path
        page.slug = "changed"
        page.save
        ::Content.publish(@final_revision, [page.id])
        page.children.each do |child|
          history = child.reload.path_history
          history.length.must_equal 1
          path = history.first
          path.path.must_match %r(^#{old_path})
          path.revision.must_equal @final_revision
        end
      end

      it 'only inserts a single history entry for multiple changes in a single publish' do
        first = Page.first uid: '1'
        middle = Page.first uid: '1.1.1'
        last = middle.things << Page.new(uid: '1.1.1.1', slug: 'p-1-1-1-1')
        ::Content.publish(@final_revision, [last.id])

        history = last.reload.path_history
        history.length.must_equal 0

        revision = @final_revision + 1

        old_path = last.reload.path

        first.slug = 'first'
        first.save
        middle.slug = 'middle'
        middle.save

        ::Content.publish(revision, [first.id, middle.id])
        history = last.reload.path_history
        last.path.must_equal '/first/middle/p-1-1-1-1'
        history.length.must_equal 1
        path = history.first
        path.path.must_equal old_path
        path.revision.must_equal revision
      end

      it 'doesn’t insert a history item on first publish for updated slugs' do
        first = Page.first uid: '1'
        middle = Page.first uid: '1.1.1'
        last = middle.things << Page.new
        last.slug = 'something-sluggy'
        last.save
        ::Content.publish(@final_revision, [last.id])
        history = last.reload.path_history
        history.length.must_equal 0
      end
    end
  end

  describe "with assigned editor" do
    before do
      Spontaneous::Permissions::User.delete
      @user = Spontaneous::Permissions::User.create(email: "root@example.com", login: "root", name: "root", password: "rootpass")
    end

    after do
      @user.destroy
    end

    it "add the editor to any modifications" do
      Timecop.freeze(@now+3600) do
        page = Page.first uid: "1"
        page.current_editor = @user
        page.slug = "changed"
        page.save
        mod = page.pending_modifications(:slug).first
        mod.user.must_equal @user
      end
    end

    it "persist the user" do
      Timecop.freeze(@now+3600) do
        page = Page.first uid: "1"
        page.current_editor = @user
        page.slug = "changed"
        page.save
        page = Page.first uid: "1"
        mod = page.pending_modifications(:slug).first
        mod.user.must_equal @user
      end
    end
  end
end
