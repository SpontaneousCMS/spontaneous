# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

describe "Skeptick" do
  extend  Spontaneous::Media::Image::Skeptick
  include Spontaneous::Media::Image::Skeptick

  start do
    pwd = Dir.mktmpdir

    large = image do
      canvas :none, size: "400x800"
    end

    image = convert(large, to: pwd / "large.jpg")
    image.build

    small = image do
      canvas :none, size: "20x40"
    end

    image = convert(small, to: pwd / "small.jpg")
    image.build

    let(:pwd) { pwd }
    let(:large_image) { pwd / "large.jpg" }
    let(:small_image) { pwd / "small.jpg" }
  end

  def resize!(src, debug = false, &block)
    cmd = convert(src, to: resized_image, &block)
    cmd.build
    system "open #{resized_image}" if debug
    Spontaneous::Media::Image.dimensions(resized_image)
  end

  let(:resized_image) { pwd / "resized.jpg" }

  it "correctly sets the height" do
    size = resize!(large_image) do
      height 100
    end
    size.must_equal [50, 100]
  end

  it "doesn't enlarge an image to set the height" do
    size = resize!(small_image) do
      height 100
    end
    size.must_equal [20, 40]
  end

  it "enlarges an image to set the height if asked" do
    size = resize!(small_image) do
      height 100, enlarge: true
    end
    size.must_equal [50, 100]
  end

  it "correctly sets the width" do
    size = resize!(large_image) do
      width 100
    end
    size.must_equal [100, 200]
  end

  it "doesn't enlarge an image to set the width" do
    size = resize!(small_image) do
      width 100
    end
    size.must_equal [20, 40]
  end

  it "enlarges an image to set the width if asked" do
    size = resize!(small_image) do
      width 100, enlarge: true
    end
    size.must_equal [100, 200]
  end

  it "correctly resizes to fill" do
    size = resize!(large_image) do
      fill width: 100, height: 100
    end
    size.must_equal [100, 100]
  end

  it "doesn't expand an image to fill by default" do
    size = resize!(small_image) do
      fill width: 100, height: 100
    end
    size.must_equal [20, 40]
  end

  it "expands an image to fill if asked" do
    size = resize!(small_image) do
      fill width: 100, height: 100, enlarge: true
    end
    size.must_equal [100, 100]
  end

  it "correctly resizes to fit" do
    size = resize!(large_image) do
      fit width: 100, height: 100
    end
    size.must_equal [50, 100]
  end

  it "doesn't expand an image to fit by default" do
    size = resize!(small_image) do
      fit width: 100, height: 100
    end
    size.must_equal [20, 40]
  end

  it "expands an image to fit if asked" do
    size = resize!(small_image) do
      fit width: 100, height: 100, enlarge: true
    end
    size.must_equal [50, 100]
  end

  # it "creates a rounded version" do
  #   size = resize!(large_image, true) do
  #     fill width: 100, height: 100
  #     rounded 5
  #   end
  # end
end
