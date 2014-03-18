require 'foreman/engine/cli'



require File.expand_path('../../test_helper', __FILE__)


describe "CLI" do
  let(:cli) { Spontaneous::Cli }
  let(:root) { cli::Root }

  describe "Console" do
    let(:cmd) { cli::Console }
    it "maps 'spot console' to Console#open" do
      cmd.any_instance.expects(:open_console)
      root.start(["console"])
    end
    it "maps 'spot c' to Console#open" do
      cmd.any_instance.expects(:open_console)
      root.start(["c"])
    end
  end

  describe "Server" do
    let(:cmd) { cli::Server }

    def expect_subcommand_launch
      foreman = mock()
      foreman.expects(:register).with("front", regexp_matches(/spot server front/))
      foreman.expects(:register).with("back", regexp_matches(/spot server back/))
      foreman.expects(:register).with("tasks", regexp_matches(/spot server tasks/))
      foreman.expects(:start)
      ::Foreman::Engine::CLI.expects(:new).returns(foreman)
    end

    it "maps 'spot server' to Server#start" do
      cmd.any_instance.expects(:start)
      root.start(["server"])
    end

    it "'spot server' launches front & back" do
      expect_subcommand_launch
      root.start(["server"])
    end

    it "'spot s' launches front & back" do
      expect_subcommand_launch
      root.start(["s"])
    end

    it "maps 'spot server back' to Server#back" do
      silence_logger do
        cmd.any_instance.expects(:start_server).with(:back)
        root.start(["server", "back"])
      end
    end

    it "maps 'spot s back' to Server#back" do
      silence_logger do
        cmd.any_instance.expects(:start_server).with(:back)
        root.start(["s", "back"])
      end
    end

    it "maps 'spot server front' to Server#front" do
      silence_logger do
        cmd.any_instance.expects(:start_server).with(:front)
        root.start(["server", "front"])
      end
    end

    it "maps 'spot s front' to Server#front" do
      silence_logger do
        cmd.any_instance.expects(:start_server).with(:front)
        root.start(["s", "front"])
      end
    end

    it "maps 'spot server tasks' to Server#tasks" do
      silence_logger do
        cmd.any_instance.expects(:start_simultaneous)
        root.start(["server", "tasks"])
      end
    end

    it "maps 'spot s tasks' to Server#tasks" do
      silence_logger do
        cmd.any_instance.expects(:start_simultaneous)
        root.start(["s", "tasks"])
      end
    end
  end

  describe "User" do
    let(:cmd) { cli::User }
    it "maps 'spot user' to User#add" do
      cmd.any_instance.expects(:add_user)
      root.start(["user"])
    end

    it "maps 'spot user add' to User#add" do
      cmd.any_instance.expects(:add_user)
      root.start(["user", "add"])
    end

    it "maps 'spot user list' to User#list" do
      cmd.any_instance.expects(:list_users)
      root.start(["user", "list"])
    end

    it "maps 'spot user authenticate' to User#authenticate" do
      cmd.any_instance.expects(:authenticate_user).with("garry", "fishingrod")
      root.start(["user", "authenticate", "garry", "fishingrod"])
    end
  end
  describe "Generate" do
    let(:cmd) { cli::Generate }
    let(:generator) { ::Spontaneous::Generators::Site }
    it "maps 'generate site' to Generate#site" do
      generator.expects(:start).with([])
      root.start(["generate", "site"])
    end

    it "maps 'generate example.com' to Generate#site" do
      generator.expects(:start).with(['example.com'])
      root.start(["generate", "example.com"])
    end

  end

  describe "Assets" do
    let(:cmd) { cli::Assets }
    it "maps 'spot assets compile' to Assets#compile" do
      cmd.any_instance.expects(:compile_assets)
      root.start(["assets", "compile", "--destination=/tmp/destination"])
    end
  end

  describe "Content" do
    let(:cmd) { cli::Content }
    it "maps 'spot content clean' to Content#clean" do
      cmd.any_instance.expects(:clean_content)
      root.start(["content", "clean"])
    end
  end
end