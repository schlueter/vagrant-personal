module VagrantPlugins
  module PersonalFolders
    class Plugin < Vagrant.plugin("2")

      name "ENV"
      description <<-DESC
        Get, store, and make available to Vagrant, personalized information about local folders.
      DESC

      action_hook 'personalfolders_setup', :environment_load do |hook|
        # TODO figure out if this is what we want to do here
        require 'personalfolders/action'
        hook.prepend Action.configure
      end

    end
  end
end
