# encoding: UTF-8

require 'test_helper'


class SidColumnsTest < MiniTest::Spec
  UID = Spontaneous::Schema::UID

  context "Schema UID columns" do
    setup do
      class ::M < Sequel::Model(:content); end
      M.plugin :schema_uid, :type_sid, :style_sid, :box_sid
    end

    teardown do
      M.delete
      Object.send(:remove_const, :M)
    end

    should "be settable with UIDS" do
      instance = M.new
      instance.type_sid = UID["abcd"]
      instance.type_sid.must_be_instance_of(UID)
      instance.save
      instance = M[instance.id]
      instance.type_sid.must_be_instance_of(UID)
    end

    should "be settable with strings" do
      instance = M.new
      instance.style_sid = "abcd"
      instance.style_sid.must_be_instance_of(UID)
      instance.save
      instance = M[instance.id]
      instance.style_sid.must_be_instance_of(UID)
    end

    should "work with nils" do
      instance = M.new
      instance.type_sid = nil
      instance.type_sid.should be_nil
      instance.save
      instance = M[instance.id]
      instance.type_sid.should be_nil
    end
  end
end
