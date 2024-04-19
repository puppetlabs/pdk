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

Specinfra::Configuration.singleton_class.send(:remove_const, :VALID_OPTIONS_KEYS) # rubocop:disable RSpec/RemoveConst
Specinfra::Configuration.singleton_class.const_set(:VALID_OPTIONS_KEYS, option_keys.freeze)
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
        if get_config(:cwd)
          cmd = cmd.shelljoin if cmd.is_a? Array
          cmd = "cd #{get_config(:cwd)} && #{cmd}"
        end

        prepend_env(old_build_command.bind_call(self, cmd))
      end

      def unescape(string)
        JSON.parse(%(["#{string}"])).first
      end

      def prepend_env(cmd)
        _, orig_env, orig_cmd = cmd.match(/\A(?:env (.+) )?(\S+(?: -i)?(?: -l)? -c .+)\Z/).to_a

        env = [orig_env].compact
        (get_config(:env) || {}).each do |k, v|
          env << %(#{k}="#{v}")
        end

        command = if env.empty?
                    orig_cmd
                  else
                    "env #{env.join(' ')} #{orig_cmd}"
                  end

        output = if get_config(:run_as)
                   "su -l #{get_config(:run_as)} -c #{command.shellescape}"
                 else
                   command
                 end

        $stderr.puts(output) if ENV.key?('BEAKER_debug')
        output
      end
    end
  end
end
