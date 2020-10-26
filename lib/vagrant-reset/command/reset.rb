require 'optparse'

module VagrantReset
  module Command
    class CommandReset < Vagrant.plugin('2', :command)
      def execute
        opts = OptionParse.new do |opt|
          opt.banner = "Usage: vagrant reset [machine-name]"
        end

        argv = parse_options(opts)
        return if !argv

        results = []
        with_target_vms(argv) do |machine|
          results << machine.name.to_s << "\n"
          results << machine.box.destroy!
        end

        @env.ui.info(results.join("\n"))

        0
      end
    end
  end
end
