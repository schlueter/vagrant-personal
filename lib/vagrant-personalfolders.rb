begin
    require "vagrant"
rescue LoadError
    raise "The Vagrant Personal Folders plugin must be run within Vagrant."
end
require "vagrant-personalfolders/plugin"
require 'vagrant-personalfolders/version'
