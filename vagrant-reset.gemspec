require File.expand_path("../lib/vagrant-reset/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "vagrant-reset"
  s.version     = VagrantReset::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["n01e0"]
  s.email       = ["n01e0@vanillabeans.mobi"]
  s.homepage    = "https://www.feneshi.co"
  s.summary     = %q{vagrant destroy -f && vagrant up}
  s.description = %q{vagrant destroy -f && vagrant up}

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "vagrant-reset"

  s.add_development_dependency "bundler", ">= 1.0.0"

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path  = 'lib'
end
