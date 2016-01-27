# Vagrant Personal Synced Folders Plugin

This is a [Vagrant](http://www.vagrantup.com) plugin to facilitate personally configurable synced folder locations per installation. It searches upwards for a candidate and asks the user to confirm the candidate or enter their own, and will validate the chosen folder before providing information about it as variables with can be used in synced folder declarations or passed to provisioning scripts.

## Requirements

* Vagrant 1.7.4 or higher

## Installation

Install the lastest version using standard vagrant plugin installation method:

```sh
$ vagrant plugin install vagrant-personal
```

To install an older version of the plugin use `vagrant plugin install vagrant-personal --plugin-version VERSION`

## Usage

After installing, the plugin can be configured in your Vagrantfile:

```ruby
Vagrant.configure(2) do |config|
  if Vagrant.has_plugin?('vagrant-personal-synced-folders')
    config.personal.synced_folders = [{ name:       'Bugs',
                                        validate:   'git+empty'},

                                      { name:       'Daffy',
                                        validate:   'git+empty'},

                                      { name:       'Tweety',
                                        guest_path: '/srv/tweety',
                                        validate:   'git+empty'}]

    config.personal.save_file = cwd.join 'looney-config.yml'
  else
    cwd = Pathname __dir__
    # This is only necessary if you want to support systems without the plugin
    # The plugin provides a customized version of this hash.
    personal = {host_ip_address: IPAddr.new(guest_ipaddress).mask('255.255.255.0).succ,
                synced_folders: [{ name: 'Bugs',
                                   host_path: cwd.join 'Bugs',
                                   git_branch: 'master'}

                                 { name: 'Daffy',
                                   host_path: cwd.join 'Daffy',
                                   git_branch: 'master'}

                                 { name: 'Tweety',
                                   host_path: cwd.join 'Tweety',
                                   guest_path: '/srv/tweety',
                                   guest_path: '/srv/tweety'}]
  end
  …
end
```

With that snippet (or just the `config.personal` line) in your Vagrantfile, the personal plugin will search up the directory tree for each of the listed folders, validating according to the `validate` value before accepting. The user will be prompted for confirmation of any found location and may enter a different location if they choose. Whatever location is chosen will be validated again. Once the user has answered the prompts, the entered information, along with the discovered IP address for the host machine will be saved to disk at the location specified by `config.personal.save_file` or at *$[${VAGRANT_DOTFILE_PATH}](https://docs.vagrantup.com/v2/other/environmental-variables.html)/personal/config.yml* so that the user will not need to be prompted again. If the user wishes to change the settings, they may do so by appending the `--repersonalize` or `-r` to one of `vagrant up`, `vagrant provision` or `vagrant reload`.

Once the configuration has been saved, vagrant will continue whatever task it was given, but with a new variable, `personal` containing the hash of the collected config information, and the defined *name* and *guest_path*. This information may be used to set up new synced folders, or may be provided to a provisioning run for whatever you want to use it for.

Used with vagrant synced folders:

```ruby
Vagrant.configure(2) do |config|
  guest_ipaddress = 192.168.33.29
  cwd = Pathname __dir__
  config.personal.synced_folders = [{name: 'Bugs',
                                     guest_path: '/srv/bugs',
                                     validate: 'git+empty'},
                                    {name: 'Daffy',
                                     guest_path: '/srv/daffy',
                                     validate: 'git+empty'},
                                    {name: 'Tweety',
                                     guest_path: '/srv/tweety',
                                     validate: 'git+empty'}]
  personal.synced_folders.each do |synced_folder|
      config.vm.synced_folder synced_folders.host_path, "/srv/#{synced_folder.name}"
  end
  …
end
```

Passed to a provisioner:

```ruby
Vagrant.configure(2) do |config|
  guest_ipaddress = 192.168.33.29
  cwd = Pathname __dir__
  config.personal.synced_folders = [{name: 'Bugs',
                                     guest_path: '/srv/bugs',
                                     validate: 'git+empty'},
                                    {name: 'Daffy',
                                     guest_path: '/srv/daffy',
                                     validate: 'git+empty'},
                                    {name: 'Tweety',
                                     guest_path: '/srv/tweety',
                                     validate: 'git+empty'}]
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbook.yml"
    ansible.extra_vars = personal
  end
  …
end
```

The `personal` object may be accessed either with properties or as a hash, which is how it may be passed directly to Ansible's extra_vars option.

## Contributing

1. Fork it ( https://github.com/gosuri/vagrant-env/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
