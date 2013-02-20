# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

# borrowed from Padrino
describe "Logger" do
  include Spontaneous

  before do
    Spontaneous.env = :test
    Spontaneous::Logger::Config[:test][:stream] = :null # The default
    Spontaneous::Logger.setup!
  end

  def setup_logger(options={})
    @log    = StringIO.new
    @logger = Spontaneous::Logger.new(options.merge(:stream => @log))
  end

  describe 'for logger functionality' do

    describe 'check stream config' do

      it 'use stdout if stream is nil' do
        Spontaneous::Logger::Config[:test][:stream] = nil
        Spontaneous::Logger.setup!
        assert_equal $stdout, Spontaneous.logger.log
      end

      it 'use StringIO as default for test' do
        assert_instance_of StringIO, Spontaneous.logger.log
      end

      it 'use a custom stream' do
        my_stream = StringIO.new
        Spontaneous::Logger::Config[:test][:stream] = my_stream
        Spontaneous::Logger.setup!
        assert_equal my_stream, Spontaneous.logger.log
      end

      describe "with custom log file path" do
        before do
          @relative_path = "tmp/log/mylogfile.log"
        end

        after do
          FileUtils.rm_r(@relative_path) if File.exists?(@relative_path)
        end

        it "log to given file" do
          logger = Spontaneous::Logger.setup(:logfile => @relative_path)
          logger.log.path.must_equal @relative_path
        end
      end
    end

    it 'log something' do
      setup_logger(:log_level => :error)
      @logger.error "You log this error?"
      assert_match(/You log this error?/, @log.string)
      @logger.debug "You don't log this error!"
      refute_match(/You don't log this error!/, @log.string)
      @logger << "Yep this can be logged"
      assert_match(/Yep this can be logged/, @log.string)
    end

    it "be silenceable" do
      setup_logger(:log_level => :debug)
      @logger.silent!
      @logger.error "You log this error?"
      assert_empty(@log.string)
      @logger.resume!
      @logger.error "You log this error?"
      assert_match(/You log this error?/, @log.string)
    end
  end
end
