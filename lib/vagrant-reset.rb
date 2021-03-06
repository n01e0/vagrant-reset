# -*- encoding: utf-8 -*-
require "vagrant"

module VagrantReset
  class Plugin < Vagrant.plugin('2')
    name 'vagrant-reset'
    description <<-EOS
    Vagrant reset
    vagrant destroy -f && vagrant up
    EOS

    command("reset") do
      require File.expand_path("../vagrant-reset/command/reset", __FILE__)
      Command::CommandReset
    end
  end
end
