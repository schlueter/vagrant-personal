# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = 'ubuntu/vivid64'

  config.vm.define :vagrantlocal do |instance|

    instance.vm.provision :shell,
      inline: "echo Hello, World\!"

  end
end
