require 'beaker-rspec'

module Serverspec
  module Type
    class Command
      def run
        command_result
      end
    end
  end
end

option_keys = Specinfra::Configuration.singleton_class.const_get(:VALID_OPTIONS_KEYS).dup
option_keys << :cwd
option_keys << :run_as

stub_const('Specinfra::Configuration::VALID_OPTIONS_KEYS', options.keys.freeze)
RSpec.configuration.add_setting :cwd
RSpec.configuration.add_setting :run_as

module Specinfra
  module Backend
    class BeakerCygwin
      old_create_script = instance_method(:create_script)

      define_method(:create_script) do |cmd|
        prepend_env(old_create_script.bind_call(self, cmd))
      end

      def prepend_env(script)
        cmd = []

        cmd << %(Set-Location -Path "#{get_config(:cwd)}") if get_config(:cwd)
        (get_config(:env) || {}).each do |k, v|
          cmd << %($env:#{k} = "#{v}")
        end
        cmd << script

        cmd.join("\n")
      end
    end
  end
end

module Specinfra
  module Backend
    class BeakerExec
      old_build_command = instance_method(:build_command)

      define_method(:build_command) do |cmd|
        prepend_env(old_build_command.bind_call(self, cmd))
      end

      def unescape(string)
        JSON.parse(%(["#{string}"])).first
      end

      def prepend_env(cmd)
        _, env, shell, command = cmd.match(/\Aenv (.+?)? (\S+) -c (.+)\Z/).to_a

        output = if get_config(:run_as)
                   ["sudo -u #{get_config(:run_as)}"]
                 else
                   ['env']
                 end

        (get_config(:env) || {}).each do |k, v|
          output << %(#{k}="#{v}")
        end
        output << env
        new_cmd = if get_config(:cwd)
                    "'cd #{get_config(:cwd).shellescape} && #{unescape(command)}'"
                  else
                    "'#{unescape(command)}'"
                  end
        output << '-i --' if get_config(:run_as)

        # sudo on osx 10.11 behaves strangely when processing arguments and does
        # not preserve quoted arguments, so we have to quote twice for this corner
        # case.
        output << if Specinfra.get_working_node.platform.start_with?('osx-10.11-') && get_config(:run_as)
                    "#{shell} -c \"#{new_cmd}\""
                  else
                    "#{shell} -c #{new_cmd}"
                  end

        $stderr.puts(output.join(' ')) if ENV.key?('BEAKER_debug')
        output.join(' ')
      end
    end
  end
end
