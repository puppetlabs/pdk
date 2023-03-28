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
      allow(PDK::Util::RubyVersion).to receive(:gem_home).and_return('/opt/puppetlabs/pdk/share/cache/ruby/2.4.0')
      allow(PDK::Util::RubyVersion).to receive(:gem_path).and_return('/opt/puppetlabs/pdk/private/ruby/2.4.3/lib')
      allow(PDK::Util::RubyVersion).to receive(:bin_path).and_return('/opt/puppetlabs/pdk/private/ruby/2.4.3/bin')
      allow(PDK::Util::RubyVersion).to receive(:gem_paths_raw).and_return(['/opt/puppetlabs/pdk/private/ruby/2.4.3/lib'])
      allow(PDK::Util::Env).to receive(:[]).and_call_original
      allow(PDK::Util::Env).to receive(:[]).with('PATH').and_return('/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin')

      allow(PDK::CLI::Util).to receive(:puppet_from_opts_or_env)
        .and_return(ruby_version: '2.4.3', gemset: { puppet: '5.4.0' })
      allow(PDK::Util::RubyVersion).to receive(:use)
    end

    context 'and called with no arguments' do
      it 'sends a "env" screen view to analytics' do
        expect(analytics).to receive(:screen_view).with(
          'env',
          output_format: 'default',
          ruby_version: RUBY_VERSION,
        )
      end

      it 'outputs export commands for environment variables' do
        output_regexes = [
          %r{export PDK_RESOLVED_PUPPET_VERSION="\d\.\d+\.\d+"},
          %r{export PDK_RESOLVED_RUBY_VERSION="\d\.\d+\.\d+"},
          %r{export GEM_HOME=.*},
          %r{export GEM_PATH=.*},
          %r{export PATH=.*},
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
          %r{export PDK_RESOLVED_PUPPET_VERSION="\d\.\d+\.\d+"},
          %r{export PDK_RESOLVED_RUBY_VERSION="\d\.\d+\.\d+"},
          %r{export GEM_HOME=.*},
          %r{export GEM_PATH=.*},
          %r{export PATH=.*},
        ]

        output_regexes.each do |regex|
          expect($stdout).to receive(:puts).with(a_string_matching(regex))
        end
      end
    end
  end
end
