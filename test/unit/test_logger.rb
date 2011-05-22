# encoding: UTF-8


require 'test_helper'

# borrowed from Padrino
class LoggerTest < MiniTest::Spec
  include Spontaneous

  def setup
    Spontaneous.env = :test
    Spontaneous::Logger::Config[:test][:stream] = :null # The default
    Spontaneous::Logger.setup!
  end

  def setup_logger(options={})
    @log    = StringIO.new
    @logger = Spontaneous::Logger.new(options.merge(:stream => @log))
  end

  context 'for logger functionality' do

    context 'check stream config' do

      should 'use stdout if stream is nil' do
        Spontaneous::Logger::Config[:test][:stream] = nil
        Spontaneous::Logger.setup!
        assert_equal $stdout, Spontaneous.logger.log
      end

      should 'use StringIO as default for test' do
        assert_instance_of StringIO, Spontaneous.logger.log
      end

      should 'use a custom stream' do
        my_stream = StringIO.new
        Spontaneous::Logger::Config[:test][:stream] = my_stream
        Spontaneous::Logger.setup!
        assert_equal my_stream, Spontaneous.logger.log
      end

      context "with custom log file path" do
        setup do
          @relative_path = "tmp/log/mylogfile.log"
        end

        teardown do
          FileUtils.rm_r(@relative_path) if File.exists?(@relative_path)
        end

        should "log to given file" do
          logger = Spontaneous::Logger.setup(:logfile => @relative_path)
          logger.log.path.should == @relative_path
        end
      end
    end

    should 'log something' do
      setup_logger(:log_level => :error)
      @logger.error "You log this error?"
      assert_match(/You log this error?/, @log.string)
      @logger.debug "You don't log this error!"
      refute_match(/You don't log this error!/, @log.string)
      @logger << "Yep this can be logged"
      assert_match(/Yep this can be logged/, @log.string)
    end

    should "be silenceable" do
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
