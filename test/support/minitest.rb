
module TransactionalTest
  # Wraps each test in a transaction that is always rolled back. The `result`
  # dance is needed because Sequel's transaction method isn't good at returning
  # the result of the block.
  def run(runner)
    result = nil
    DB.transaction(:rollback => :always) { result = super }
    result
  end
end

class MiniTest::Spec
  include TransactionalTest
  class << self
    # Finds the top-most test, that is a test that directly inherits from
    # MiniTest::Spec.
    # Used by the runner to group tests in to logical blocks.
    def parent_suite
      a = ancestors.take_while { |a| a != MiniTest::Spec }.select { |a| Class === a }
      a.last
    end

    def start(&block)
      @start_hook = block
    end

    def finish(&block)
      @finish_hook = block
    end

    def _hooks_run
      @_hooks_run ||= []
    end

    def _run_start_hook
      _run_start_finish_hook(@start_hook, :start)
    end

    def _run_finish_hook
      if _hooks_run.include?(:start)
        _run_start_finish_hook(@finish_hook, :finish)
      end
    end

    def _run_start_finish_hook(hook, label)
      _hooks_run << label
      hook.call if hook
    end
  end
end

# This relies on the test cases supporting the ::start & ::finish hooks
# as well as the ::parent_suite method.
class StartFinishRunner < MiniTest::Unit
  def _run_suites(suites, type)
    linebreak = ""
    results = []
    grouped = suites.group_by { |suite| suite.parent_suite }
    grouped.delete(nil)

    names = grouped.keys.map(&:to_s)
    max_name_length = names.map(&:length).max

    grouped.each do |master, tests|
      output.print(output.bold("#{linebreak}#{master.to_s.ljust(max_name_length, " ")}  "))
      DB.synchronize do
        begin
          master._run_start_hook
          results.concat super(tests, type)
        ensure
          master._run_finish_hook
        end
      end
      linebreak = "\n"
    end
    results
  end
end

# I find the stream of green dots & yellow "S"s a little too strident.
# Just give me red for errors.
module Minitest
  class PlainColorize < Minitest::Colorize
    def print(string = nil)
      return stream.print if string.nil?

      case string
      when 'E', 'F'
        stream.print error(string)
      when 'S'
        stream.print bold(string)
      else
        stream.print string
      end
    end

    def error(string)
      tint([1, 31], string)
    end

    def bold(string)
      tint(1, string)
    end

    def tint(color, string)
      return string unless color_enabled?
      effects = Array(color).map { |c| "\e[#{c}m"}.join
      "#{effects}#{string}\e[0m"
    end

    # I want to be able to use these
    [:red, :green, :yellow].each { |m| public m }
  end
end

MiniTest::Unit.output = MiniTest::PlainColorize.new
