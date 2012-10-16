# encoding: UTF-8

# require 'watchr'

module ::Spontaneous::Cli
  class Console < ::Thor
    include Spontaneous::Cli::TaskUtils
    include Thor::Actions

    namespace    :console
    default_task :open

    desc "open", "Gives you console access to the current site"
    def open
      prepare! :console

      ARGV.clear
      ARGV.concat [ "--readline", "--prompt-mode", "simple" ]

      require 'irb'
      require 'irb/completion'
      require 'irb/ext/save-history'

      history_file = ::Spontaneous.root / ".irb_history"

      IRB.setup(nil)
      IRB.conf[:SAVE_HISTORY] = 100
      IRB.conf[:HISTORY_FILE] = history_file

      irb = IRB::Irb.new
      IRB.conf[:MAIN_CONTEXT] = irb.context

      irb.context.evaluate((<<-CONTEXT), __LINE__)
        module Readline
          module History
            def self.write_log(line)
              File.open('#{history_file}', 'ab') {|f| f << "\#{line}\n"}
            end
          end

          alias :old_readline :readline
          def readline(*args)
            ln = old_readline(*args)
            begin
              History.write_log(ln) unless ln.strip.empty?
            rescue
            end
            ln
          end
        end
      CONTEXT

      trap("SIGINT") do
        irb.signal_handle
      end

      catch("IRB_EXIT") do
        irb.eval_input
      end
    end
  end # Console
end # ::Spontaneous::Cli
