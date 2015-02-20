# encoding: UTF-8

require File.expand_path('../../../test_helper', __FILE__)

describe "WebVideo fields" do
  before do
    @site = setup_site
    @now = Time.now
    stub_time(@now)
    Spontaneous::State.delete
    @site.background_mode = :immediate
    @content_class = Class.new(::Piece) do
      field :video, :webvideo
    end
    @content_class.stubs(:name).returns("ContentClass")
    @instance = @content_class.new
    @field = @instance.video
  end

  after do
    teardown_site
  end

  it "have their own editor type" do
    @content_class.fields.video.export(nil)[:type].must_equal "Spontaneous.Field.WebVideo"
    @instance.video = "http://www.youtube.com/watch?v=_0jroAM_pO4&feature=feedrec_grec_index"
    fields  = @instance.export(nil)[:fields]
    fields[0][:processed_value].must_equal @instance.video.src
  end

  it "recognise youtube URLs" do
    @instance.video = "http://www.youtube.com/watch?v=_0jroAM_pO4&feature=feedrec_grec_index"
    @instance.video.value.must_equal "http://www.youtube.com/watch?v=_0jroAM_pO4&amp;feature=feedrec_grec_index"
    @instance.video.video_id.must_equal "_0jroAM_pO4"
    @instance.video.provider_id.must_equal "youtube"
  end

  it "recognise Vimeo URLs" do
    @instance.video = "http://vimeo.com/31836285"
    @instance.video.value.must_equal "http://vimeo.com/31836285"
    @instance.video.video_id.must_equal "31836285"
    @instance.video.provider_id.must_equal "vimeo"
  end

  it "recognise Vine URLs" do
    @instance.video = "https://vine.co/v/brI7pTPb3qU"
    @instance.video.value.must_equal "https://vine.co/v/brI7pTPb3qU"
    @instance.video.video_id.must_equal "brI7pTPb3qU"
    @instance.video.provider_id.must_equal "vine"
  end

  it "silently handles unknown providers" do
    @instance.video = "https://idontdovideo.com/video?id=brI7pTPb3qU"
    @instance.video.value.must_equal "https://idontdovideo.com/video?id=brI7pTPb3qU"
    @instance.video.video_id.must_equal "https://idontdovideo.com/video?id=brI7pTPb3qU"
    @instance.video.provider_id.must_equal nil
  end


  it "use the YouTube api to extract video metadata" do
    youtube_info = {"thumbnail_large" => "http://i.ytimg.com/vi/_0jroAM_pO4/hqdefault.jpg", "thumbnail_small"=>"http://i.ytimg.com/vi/_0jroAM_pO4/default.jpg", "title" => "Hilarious QI Moment - Cricket", "description" => "Rob Brydon makes a rather embarassing choice of words whilst discussing the relationship between a cricket's chirping and the temperature. Taken from QI XL Series H episode 11 - Highs and Lows", "user_name" => "morthasa", "upload_date" => "2011-01-14 19:49:44", "tags" => "Hilarious, QI, Moment, Cricket, fun, 11, stephen, fry, alan, davies, Rob, Brydon, SeriesH, Fred, MacAulay, Sandi, Toksvig", "duration" => 78, "stats_number_of_likes" => 297, "stats_number_of_plays" => 53295, "stats_number_of_comments" => 46}#.symbolize_keys

    response_xml_file = File.expand_path("../../../fixtures/fields/youtube_api_response.xml", __FILE__)
    connection = mock()
    Spontaneous::Field::WebVideo::YouTube.any_instance.expects(:open).with("http://gdata.youtube.com/feeds/api/videos/_0jroAM_pO4?v=2").returns(connection)
    doc = Nokogiri::XML(File.open(response_xml_file))
    Nokogiri.expects(:XML).with(connection).returns(doc)
    @field.value = "http://www.youtube.com/watch?v=_0jroAM_pO4"
    @field.values.must_equal youtube_info.merge(:video_id => "_0jroAM_pO4", :provider => "youtube", :html => "http://www.youtube.com/watch?v=_0jroAM_pO4")
  end

  it "use the Vimeo api to extract video metadata" do
    vimeo_info = {"id"=>29987529, "title"=>"Neon Indian Plays The UO Music Shop", "description"=>"Neon Indian plays electronic instruments from the UO Music Shop, Fall 2011. Read more at blog.urbanoutfitters.com.", "url"=>"http://vimeo.com/29987529", "upload_date"=>"2011-10-03 18:32:47", "mobile_url"=>"http://vimeo.com/m/29987529", "thumbnail_small"=>"http://b.vimeocdn.com/ts/203/565/203565974_100.jpg", "thumbnail_medium"=>"http://b.vimeocdn.com/ts/203/565/203565974_200.jpg", "thumbnail_large"=>"http://b.vimeocdn.com/ts/203/565/203565974_640.jpg", "user_name"=>"Urban Outfitters", "user_url"=>"http://vimeo.com/urbanoutfitters", "user_portrait_small"=>"http://b.vimeocdn.com/ps/251/111/2511118_30.jpg", "user_portrait_medium"=>"http://b.vimeocdn.com/ps/251/111/2511118_75.jpg", "user_portrait_large"=>"http://b.vimeocdn.com/ps/251/111/2511118_100.jpg", "user_portrait_huge"=>"http://b.vimeocdn.com/ps/251/111/2511118_300.jpg", "stats_number_of_likes"=>85, "stats_number_of_plays"=>26633, "stats_number_of_comments"=>0, "duration"=>100, "width"=>1280, "height"=>360, "tags"=>"neon indian, analog, korg, moog, theremin, micropiano, microkorg, kaossilator, kaossilator pro", "embed_privacy"=>"anywhere"}.symbolize_keys

    connection = mock()
    connection.expects(:read).returns(Spontaneous.encode_json([vimeo_info]))
    Spontaneous::Field::WebVideo::Vimeo.any_instance.expects(:open).with("http://vimeo.com/api/v2/video/29987529.json").returns(connection)
    @field.value = "http://vimeo.com/29987529"
    @field.values.must_equal vimeo_info.merge(:video_id => "29987529", :provider => "vimeo", :html => "http://vimeo.com/29987529")
  end

  describe "with player settings" do
    before do
      @content_class.field :video2, :webvideo, :player => {
        :width => 680, :height => 384,
        :fullscreen => true, :autoplay => true, :loop => true,
        :showinfo => false,
        :youtube => { :theme => 'light', :hd => true, :controls => false },
        :vimeo => { :color => "ccc", :api => true }
      }
      @instance = @content_class.new
      @field = @instance.video2
    end

    it "use the configuration in the youtube player HTML" do
      @field.value = "http://www.youtube.com/watch?v=_0jroAM_pO4&feature=feedrec_grec_index"
      html = @field.render(:html)
      html.must_match /^<iframe/
      html.must_match %r{src="//www\.youtube\.com/embed/_0jroAM_pO4}
      html.must_match /width="680"/
      html.must_match /height="384"/
      html.must_match /theme=light/
      html.must_match /hd=1/
      html.must_match /fs=1/
      html.must_match /controls=0/
      html.must_match /autoplay=1/
      html.must_match /showinfo=0/
      html.must_match /showsearch=0/
      @field.render(:html, :youtube => {:showsearch => 1}).must_match /showsearch=1/
      @field.render(:html, :youtube => {:theme => 'dark'}).must_match /theme=dark/
      @field.render(:html, :width => 100).must_match /width="100"/
      @field.render(:html, :loop => true).must_match /loop=1/
    end

    it "use the configuration in the Vimeo player HTML" do
      @field.value = "http://vimeo.com/31836285"
      html = @field.render(:html)
      html.must_match /^<iframe/
      html.must_match %r{src="//player\.vimeo\.com/video/31836285}
      html.must_match /width="680"/
      html.must_match /height="384"/
      html.must_match /color=ccc/
      html.must_match /webkitAllowFullScreen="yes"/
      html.must_match /allowFullScreen="yes"/
      html.must_match /autoplay=1/
      html.must_match /title=0/
      html.must_match /byline=0/
      html.must_match /portrait=0/
      html.must_match /api=1/
      @field.render(:html, :vimeo => {:color => 'f0abcd'}).must_match /color=f0abcd/
      @field.render(:html, :loop => true).must_match /loop=1/
      @field.render(:html, :title => true).must_match /title=1/
      @field.render(:html, :title => true).must_match /byline=0/
    end

    it "provide a version of the YouTube player params in JSON/JS format" do
      @field.value = "http://www.youtube.com/watch?v=_0jroAM_pO4&feature=feedrec_grec_index"
      json = Spontaneous::JSON.parse(@field.render(:json))
      json[:"tagname"].must_equal "iframe"
      json[:"tag"].must_equal "<iframe/>"
      attr = json[:"attr"]
      attr.must_be_instance_of(Hash)
      attr[:"src"].must_match %r{^//www\.youtube\.com/embed/_0jroAM_pO4}
      attr[:"src"].must_match /theme=light/
      attr[:"src"].must_match /hd=1/
      attr[:"src"].must_match /fs=1/
      attr[:"src"].must_match /controls=0/
      attr[:"src"].must_match /autoplay=1/
      attr[:"src"].must_match /showinfo=0/
      attr[:"src"].must_match /showsearch=0/
      attr[:"width"].must_equal 680
      attr[:"height"].must_equal 384
      attr[:"frameborder"].must_equal "0"
      attr[:"type"].must_equal "text/html"
    end

    it "provide a version of the Vimeo player params in JSON/JS format" do
      @field.value = "http://vimeo.com/31836285"
      json = Spontaneous::JSON.parse(@field.render(:json))
      json[:"tagname"].must_equal "iframe"
      json[:"tag"].must_equal "<iframe/>"
      attr = json[:"attr"]
      attr.must_be_instance_of(Hash)
      attr[:"src"].must_match /color=ccc/
      attr[:"src"].must_match /autoplay=1/
      attr[:"src"].must_match /title=0/
      attr[:"src"].must_match /byline=0/
      attr[:"src"].must_match /portrait=0/
      attr[:"src"].must_match /api=1/
      attr[:"webkitAllowFullScreen"].must_equal "yes"
      attr[:"allowFullScreen"].must_equal "yes"
      attr[:"width"].must_equal 680
      attr[:"height"].must_equal 384
      attr[:"frameborder"].must_equal "0"
      attr[:"type"].must_equal "text/html"
    end


    it "can properly embed a Vine video" do
      @field.value = "https://vine.co/v/brI7pTPb3qU"
      embed = @field.render(:html)
      embed.must_match %r(iframe)
      embed.must_match %r(src=["']//vine\.co/v/brI7pTPb3qU/card["'])
      # Vine videos are square
      embed.must_match %r(width=["']680["'])
      embed.must_match %r(height=["']680["'])
    end

    it "falls back to a simple iframe for unknown providers xxx" do
      @field.value = "https://unknownprovider.net/xx/brI7pTPb3qU"
      embed = @field.render(:html)
      embed.must_match %r(iframe)
      embed.must_match %r(src=["']https://unknownprovider.net/xx/brI7pTPb3qU["'])
      embed.must_match %r(width=["']680["'])
      embed.must_match %r(height=["']384["'])
    end
  end
end
