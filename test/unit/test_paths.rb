# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


describe "Paths" do
  let(:root) { Dir.mktmpdir }
  let(:paths) { Spontaneous::Paths.new(root) }
  it "creates paths that are marked as ensure" do
    paths.add :compiled_assets, "private/assets", ensure: true
    File.exist?(File.join(root, "private/assets")).must_equal true
  end
end

