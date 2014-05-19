# encoding: UTF-8

Sequel.migration do
  up do
    [:content, :spontaneous_content_archive, :spontaneous_content_history].each do |table|
      alter_table table do
        add_column :content_hash, :varchar, size: 32
        add_column :published_content_hash, :varchar, size: 32
        add_column :content_hash_changed, :boolean, default: true
      end
    end
    alter_table :content do
      add_index :content_hash_changed
    end

    # testing environment
    if defined?(Content)

      self.logger = nil

      state = Spontaneous::State.first

      published_revision = state.nil? ? nil : state[:published_revision]

      content_hash = published_content_hash = nil

      model = Spontaneous::Model(:content)

      update_content_hashes = Proc.new do |content|
        published_content_hash = nil
        content_hash = content.calculate_content_hash!
        if published_revision
          model.mapper.scope(published_revision, false) do
            published = model[content.id]
            published_content_hash = published.calculate_content_hash! if published
          end
        end
        p [content.id, content.class, content.path, content_hash, published_content_hash] #if published_content_hash != content_hash
        model.dataset.unfiltered.where(id: content.id).update(content_hash: content_hash, published_content_hash: published_content_hash, content_hash_changed: (content_hash != published_content_hash))
      end

      Content::Piece.dataset.order(Sequel.desc(:depth)).each(&update_content_hashes)
      Content::Page.dataset.each(&update_content_hashes)
    end
  end

  down do
    alter_table :content do
      drop_index :content_hash_changed
    end
    [:spontaneous_content_archive, :spontaneous_content_history].each do |table|
      alter_table table do
        drop_column :content_hash
        drop_column :published_content_hash
        drop_column :content_hash_changed
      end
    end
  end
end
