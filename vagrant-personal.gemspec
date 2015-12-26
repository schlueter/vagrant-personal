lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-personalfolders/version'

Gem::Specification.new do |spec|
  spec.authors       = 'Brandon Schlueter'
  spec.name          = 'vagrant-personalfolders'
  spec.version       = VagrantPlugins::PersonalFolders::VERSION
  spec.email         = 'b@schlueter.blue'
  spec.summary       = 'Vagrant plugin to select personal locations for folders which can be used by Vagrant'
  spec.homepage      = 'http://github.com/schlueter/vagrant-personalfolders'
  spec.license       = 'MIT'
  spec.files         = `git ls-files`.split($/)
  spec.platform      = Gem::Platform::RUBY
  spec.require_paths = %w(lib)

  spec.add_runtime_dependency 'yaml'
end
