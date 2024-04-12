require 'spec_helper'
require 'pdk/cli'

describe 'Running `pdk env`' do
  let(:command_args) { ['env'] }
  let(:command_result) { { exit_code: 0 } }

  context 'when it calls env successfully' do
    after do
      expect do
        PDK::CLI.run(command_args)
      end.to exit_zero
    end

    before do
      allow(PDK::Util::RubyVersion).to receive_messages(gem_home: '/opt/puppetlabs/pdk/share/cache/ruby/2.4.0', gem_path: '/opt/puppetlabs/pdk/private/ruby/2.4.3/lib',
                                                        bin_path: '/opt/puppetlabs/pdk/private/ruby/2.4.3/bin', gem_paths_raw: ['/opt/puppetlabs/pdk/private/ruby/2.4.3/lib'])
      allow(PDK::Util::Env).to receive(:[]).and_call_original
      allow(PDK::Util::Env).to receive(:[]).with('PATH').and_return('/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin')

      allow(PDK::CLI::Util).to receive(:puppet_from_opts_or_env)
        .and_return(ruby_version: '2.4.3', gemset: { puppet: '5.4.0' })
      allow(PDK::Util::RubyVersion).to receive(:use)
    end

    context 'and called with no arguments' do
      it 'outputs export commands for environment variables' do
        output_regexes = [
          /export PDK_RESOLVED_PUPPET_VERSION="\d\.\d+\.\d+"/,
          /export PDK_RESOLVED_RUBY_VERSION="\d\.\d+\.\d+"/,
          /export GEM_HOME=.*/,
          /export GEM_PATH=.*/,
          /export PATH=.*/
        ]

        output_regexes.each do |regex|
          expect($stdout).to receive(:puts).with(a_string_matching(regex))
        end
      end
    end

    context 'and called with a puppet version' do
      let(:command_args) { super() + ['--puppet-version=6'] }

      it 'outputs export commands for environment variables' do
        output_regexes = [
          /export PDK_RESOLVED_PUPPET_VERSION="\d\.\d+\.\d+"/,
          /export PDK_RESOLVED_RUBY_VERSION="\d\.\d+\.\d+"/,
          /export GEM_HOME=.*/,
          /export GEM_PATH=.*/,
          /export PATH=.*/
        ]

        output_regexes.each do |regex|
          expect($stdout).to receive(:puts).with(a_string_matching(regex))
        end
      end
    end
  end
end
