# encoding: UTF-8

require 'logger'

Sequel.migration do
  # Somehow hidden state & hidden origin have become out of sync
  # some visibility changes have not propagated, so children with a
  # non-nil hidden_origin have a different visibility to that of the
  # item pointed to by hidden_origin...
  up do
    content = self[:content]
    invalid_rows = content.from(:content, :content___hc).select(:content__id).where(content__hidden_origin: nil).invert.where(hc__id: :content__hidden_origin, hc__hidden: false).flat_map(&:values)
    content.where(id: invalid_rows).update(hidden: false, hidden_origin: nil)
  end

  down do
    # no-op
  end
end
