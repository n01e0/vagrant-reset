require 'optparse'
require 'set'
require 'vagrant'

module VagrantReset
  module Command
    class CommandReset < Vagrant.plugin('2', :command)
      def execute
        options = {}
        options[:destroy_on_error] = true
        options[:install_provider] = true
        options[:parallel] = true
        options[:provision_ignore_sentinel] = false
        options[:force] = false 
        options[:force_halt] = true

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant reset [options] [name|id]"
          o.separator ""
          o.separator "Options:"
          o.separator ""
          
          options[:provision_types] = nil

          o.on("--[no-]provision", "Enable or disable provisioning") do |p|
            options[:provision_enabled] = p
            options[:provision_ignore_sentinel] = true
          end

          o.on("--provision-with x,y,z", Array, "Enable only certain provisioners, by type or by name.") do |list|
            options[:provision_types] = list.map { |type| type.to_sym }
            options[:provision_enabled] = true
            options[:provision_ignore_sentinel] = true
          end
          
          o.on("-f", "--force", "Destroy without confirmation.") do |f|
            options[:force] = f
          end

          o.on("--[no-]parallel", "Enable or Disable parallelism if provider supports if (automatically enables force)") do |p|
            options[:parallel] = p
          end

          o.on("-g", "--graceful", "Gracefully powerof of VM") do |_|
            options[:force_halt] = false
          end

          o.on("--[no-]destroy-on-error",
               "Destroy machine if any fatal error happens (default to true)") do |destroy|
            options[:destroy_on_error] = destroy
          end
          
          o.on("--[no-]parallel",
               "Enable or disable parallelism if provider supports it") do |parallel|
            options[:parallel] = parallel
          end
          
          o.on("--provider PROVIDER", String,
               "Back the machine with a specific provider") do |provider|
            options[:provider] = provider
          end
          
          o.on("--[no-]install-provider",
               "If possible, install the provider if it isn't installed") do |p|
            options[:install_provider] = p
          end
        end

        argv = parse_options(opts)
        return if !argv

        if !options[:provision_types].nil?
          provisioner_names = Set.new
          with_target_vms(argv) do |machine|
            machine.config.vm.provisioners.map(&:name).each do |name|
              provisioner_names.add(name)
            end
          end

          if (provisioner_names & options[:provision_types]).empty?
            (options[:provision_types] || []).each do |type|
              klass = Vagrant.plugin("2").manager.provisoiners[type]
              if !klass
                raise Vagrant::Errors::ProvisionerFlagInvalid,
                  name: type.to_s
              end
            end
          end
        end

        machines = []
        init_status = {}
        declined = 0

        @env.batch(nil) do |batch|
          with_target_vms(argv, reverse: true) do |vm|
            init_status[vm.name] = vm.state.id
            machines << vm
            batch.action(vm, :destroy, force_confirm_destroy: true, force_halt: true)
          end
        end

        machines.each do |m|
          if m.state.id == init_status[m.name]
            declined += 1
          end
        end

        return 1 if declined == machines.length &&
                    declined != init_status.values.count(:not_created)
              
        names = argv
        if names.empty?
          autostart = false
          @env.vagrantfile.machine_names_and_options.each do |n, o|
            autostart = true if o.key?(:autostart)
            o[:autostart] = true if !o.key?(:autostart)
            names << n.to_s if o[:autostart]
          end

          names = nil if autostart && names.empty?
        end

        machines = []

        if names
          machine_names = []
          with_target_vms(names, provider: options[:provider]){|m| machine_names << m.name }
          options[:install_provider] = false if !(machine_names - names).empty?

          # If we're installing providers, then do that. We don't
          # parallelize this step because it is likely the same provider
          # anyways.
          if options[:install_provider]
            install_providers(names, provider: options[:provider])
          end

          @env.batch(options[:parallel]) do |batch|
            with_target_vms(names, provider: options[:provider]) do |machine|
              @env.ui.info(I18n.t(
                "vagrant.commands.up.upping",
                name: machine.name,
                provider: machine.provider_name))

              machines << machine

              batch.action(machine, :up, options)
            end
          end
        end

        if machines.empty?
          @env.ui.info(I18n.t("vagrant.up_no_machines"))
          return 0
        end

        # Output the post-up messages that we have, if any
        machines.each do |m|
          next if !m.config.vm.post_up_message
          next if m.config.vm.post_up_message == ""

          # Add a newline to separate things.
          @env.ui.info("", prefix: false)

          m.ui.success(I18n.t(
            "vagrant.post_up_message",
            name: m.name.to_s,
            message: m.config.vm.post_up_message))
        end

        # Success, exit status 0
        0
      end
    end
  end
end
