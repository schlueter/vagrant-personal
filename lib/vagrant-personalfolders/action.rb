require 'ipaddr'

require 'yaml'


module VagrantPlugins
  module PersonalFolders
    module Action
      CWD = Pathname __dir__
      # TODO make config file name configurable
      CONFIG_FILE = CWD.join 'personalfolders-config.yml'
      # TODO Move config file read/write to it's own class
      EDIT_WARNING = <<EOM
# Warning: This file is used by the Vagrantfile to store information about
# your Vagrant configuration. Feel free to edit it, but there is currently no
# validation on the contents of this file, meaning that if you corrupt it,
# your Vagrant instance will not work as expected!
EOM

      def parse_config(config_filename)
        begin
          config = YAML.load_file config_filename
        rescue Errno::ENOENT
          puts "No personalfolders config file exists at #{config_filename}, will create…\n\n"
        ensure
          config ||= config_definition.clone
        end

        return symbolize_keys config
      end

      # TODO Move utility functions to their own class
      def symbolize_keys(hash)
        return hash.inject({}) do |result, (key, value)|
          new_key = key.to_sym
          new_value = case value
                      when Hash
                        symbolize_keys(value)
                      when Array
                        value.map! do |element|
                          symbolize_keys element
                        end
                      else
                        value
                      end
          result[new_key] = new_value
          result
        end
      end

      def stringify_keys(hash)
        return hash.inject({}) do |result, (key, value)|
          new_key = key.to_s
          new_value = case value
                      when Hash
                        symbolize_keys(value)
                      when Array
                        value.map! do |element|
                          stringify_keys element
                        end
                      else
                        value
                      end
          result[new_key] = new_value
          result
        end
      end

      # TODO Move Guest IP address detection to its own class (and maybe see if there's a better way)
      def host_ip_address(guest_ip_address)
          nics = `VBoxManage list hostonlyifs`.split("\n\n").map do |net|
            Hash[
              # Separate the key/value pairs which are on each line
              net.split("\n").map do |line|
                # Chomp ":" off the end of all values
                line.split().each { |value| value.chomp!(":") }
              end
            ]
          end

          matching_nics = nics.select do |nic|
            vbox_nic = IPAddr.new(nic['IPAddress']).mask(nic['NetworkMask'])
            vagrant_nic = IPAddr.new(guest_ip_address).mask(nic['NetworkMask'])
            vbox_nic == vagrant_nic
          end

          if matching_nics.length > 1
            warn 'More than one matching host only interface, behaviour may be unpredictable.'
          elsif matching_nics.length == 0
            warn 'No matching host only interface, will assume host is at `.1`.'
            return IPAddr.new(guest_ip_address).mask('255.255.255.0').succ
          end

          return IPAddr.new matching_nics[0]['IPAddress']
      end

      # TODO Make folder attributes their own classes
      def git_managed_dir?(path)
        git_dir = path.join '.git'
        return git_dir.directory?
      end

      def ancestor_sibling(dirname)

        ancestor_sibling_finder = lambda do |path|
          ancestor_sibling = path.join dirname
          return ancestor_sibling if git_managed_dir? ancestor_sibling
          return nil if path.root? || !File.exist?(path)
          ancestor_sibling_finder.call path.parent
        end

        return ancestor_sibling_finder.call CWD
      end

      # TODO Vagrant::Environment.ui should be used for this
      def configure_readline_autocomplete(completion_proc)

        begin
          require 'readline'
        rescue LoadError
          puts "Readline module not available, autocomplete will not be available…\n\n"
          return false
        end

        # Provide path autocomplete to Readline
        Readline.completion_append_character = ''
        Readline.completion_proc = completion_proc
      end

      def path_proc
        Proc.new do |str|
          # Associate ~ with the HOME env var
          if str.start_with? '~'
            str.sub! '~', ENV['HOME']
          end
          # Find all directory entries beginning with str
          Dir[str + '*'].grep(/^#{Regexp.escape(str)}/)
        end
      end

      def valid_repo_info?(repo)
        unless repo.member?(:host_path) and
               repo.member?(:version) and
               repo.member?(:name) then
          return false
        end

        return true
      end

      def prompt_for_shared_repos_paths(shared_repos)
        use_readline = configure_readline_autocomplete path_proc

        shared_repos.each_with_index do |repo, index|

          repo_name = repo[:name]
          # Search for and confirm location of existing repos
          repo_path = ancestor_sibling(repo_name)

          unless repo_path
            repo_path = CWD.parent.join repo_name
          end

          begin
            prompt = "Please enter desired path to #{repo_name} or hit Enter to use \"#{repo_path}\": "
            if use_readline
              given_path = Readline.readline prompt
            else
              # TODO make this work
              puts prompt
              given_path = gets
            end
          rescue Interrupt
            puts "\n\nExiting… Please try again soon."
            exit 1
          end

          repo_path = given_path == '' ? repo_path : given_path
          puts "\nUsing \"#{repo_path}\" for #{repo_name} repository.\n\n"
          shared_repos[index].store 'host_path', repo_path.to_s

        end
      end

      def get_shared_repos_info(repos=[])
        # Array#reject creates a new array, but it contains the same object pointers as the original.
        # This means that we can loop over and make valid the invalid repos without touching
        # already valid ones, and they'll all still be in the shared_repos array.
        invalid_repos = repos.reject do |repo|
          valid_repo_info? repo
        end

        if invalid_repos.length != 0
          prompt_for_shared_repos_paths invalid_repos
        end
        return repos
      end

      def write_yaml_file(data, filename)
        data = stringify_keys data
        begin
          File.open(filename, 'w') do |file|
            file.write(EDIT_WARNING)
            file.write(YAML.dump(data))
          end
        end
      end

      # Get the config from the file set in the env var or the default file
      config_file = CONFIG_FILE
      config = parse_config config_file

      repos = config
      shared_repos = get_shared_repos_info repos

    end
  end
end
