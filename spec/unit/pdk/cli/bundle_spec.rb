require 'spec_helper'
require 'pdk/cli'

describe 'Running `pdk bundle`' do
  let(:command_args) { ['bundle'] }
  let(:command_result) { { exit_code: 0 } }

  context 'when it calls bundler successfully' do
    after(:each) do
      expect {
        PDK::CLI.run(command_args)
      }.to exit_zero
    end

    before(:each) do
      mock_command = instance_double(
        PDK::CLI::Exec::InteractiveCommand,
        :context= => true,
        :update_environment => true,
        :execute! => command_result,
      )
      allow(PDK::CLI::Exec::InteractiveCommand).to receive(:new)
        .with(PDK::CLI::Exec.bundle_bin, *(command_args[1..-1] || []))
        .and_return(mock_command)

      allow(PDK::Util).to receive(:module_root)
        .and_return(File.join('path', 'to', 'test', 'module'))
      allow(PDK::Module::Metadata).to receive(:from_file)
        .with('metadata.json').and_return({})
      allow(PDK::CLI::Util).to receive(:puppet_from_opts_or_env)
        .and_return(ruby_version: '2.4.3', gemset: { puppet: '5.4.0' })
      allow(PDK::Util::RubyVersion).to receive(:use)
    end

    context 'and called with no arguments' do
      it 'sends a "bundle" screen view to analytics' do
        expect(analytics).to receive(:screen_view).with(
          'bundle',
          output_format: 'default',
          ruby_version: RUBY_VERSION,
        )
      end
    end

    context 'and called with a bundler subcommand that is not "exec"' do
      let(:command_args) { super() + %w[config something] }

      it 'includes only the subcommand in the screen view name sent to analytics' do
        expect(analytics).to receive(:screen_view).with(
          'bundle_config',
          output_format: 'default',
          ruby_version: RUBY_VERSION,
        )
      end
    end

    context 'and called with the "exec" bundler subcommand' do
      let(:command_args) { super() + ['exec', 'rspec', 'some/path'] }

      it 'includes the name of the command being executed in the screen view sent to analytics' do
        expect(analytics).to receive(:screen_view).with(
          'bundle_exec_rspec',
          output_format: 'default',
          ruby_version: RUBY_VERSION,
        )
      end
    end
  end
end
