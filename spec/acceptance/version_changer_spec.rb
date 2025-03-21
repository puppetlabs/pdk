require 'spec_helper_acceptance'

describe 'puppet version selection' do
  context 'in a new module' do
    include_context 'in a new module', 'version_select'

    ['PUPPET', 'FACTER', 'HIERA'].each do |gem|
      context "when the legacy #{gem}_GEM_VERSION environment variable is used" do
        if Gem.win_platform?
          pre_cmd = "$env:#{gem}_GEM_VERSION='1.0.0';"
          post_cmd = "; remove-item env:\\#{gem}_GEM_VERSION"
        else
          pre_cmd = "#{gem}_GEM_VERSION=1.0.0"
          post_cmd = ''
        end

        describe command("#{pre_cmd} pdk validate#{post_cmd}") do
          # Warn is outputed as failure on non-windows
          #   Warn caused by tests being run against only a single Puppet version
          if Gem.win_platform?
            its(:exit_status) { is_expected.to eq(0) }
          else
            its(:exit_status) { is_expected.to eq(1) }
          end
          its(:stderr) { is_expected.to match(/#{gem}_GEM_VERSION is not supported by PDK/im) }
        end
      end
    end

    [PDK_VERSION[:lts][:full]].each do |puppet_version|
      context "when requesting --puppet-version #{puppet_version}" do
        describe command("pdk validate --puppet-version #{puppet_version}") do
          # Warn is outputed as failure on non-windows
          #   Warn caused by tests being run against only a single Puppet version
          if Gem.win_platform?
            its(:exit_status) { is_expected.to eq(0) }
          else
            its(:exit_status) { is_expected.to eq(1) }
          end
        end

        describe file('Gemfile.lock') do
          it { is_expected.to exist }
          its(:content) { is_expected.to match(/^\s+puppet \(#{Regexp.escape(puppet_version)}(\)|-)/im) }
        end
      end
    end

    describe 'puppet-dev uses the correct puppet env' do
      before(:all) do
        File.open(File.join('manifests', 'init.pp'), 'w') do |f|
          f.puts <<~PPFILE
            # version_select
            class version_select {
            }
          PPFILE
        end

        FileUtils.mkdir_p(File.join('spec', 'classes'))
        File.open(File.join('spec', 'classes', 'version_select_spec.rb'), 'w') do |f|
          f.puts <<~TESTFILE
            # frozen_string_literal: true

            require 'spec_helper'

            describe 'version_select' do
              context 'test env' do
                it('has path') {
                  path = Gem::Specification.find_by_name('puppet').source.options.key?('path')
                  expect(path).to be true
                }
              end
            end
          TESTFILE
        end
      end

      describe command('pdk validate') do
        its(:stderr) { is_expected.not_to match(%r{Using Puppet file://}i) }

        # Warn is outputed as failure on non-windows
        #   Warn caused by tests being run against only a single Puppet version
        if Gem.win_platform?
          its(:exit_status) { is_expected.to eq(0) }
        else
          its(:exit_status) { is_expected.to eq(1) }
        end
      end

      describe command('pdk test unit') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stderr) { is_expected.not_to match(%r{Using Puppet file://}i) }
      end

      context 'when PDK_PUPPET_VERSION is set' do
        around do |example|
          pdk_puppet_version = ENV.fetch('PDK_PUPPET_VERSION', nil)
          ENV['PDK_PUPPET_VERSION'] = nil
          example.run
          ENV['PDK_PUPPET_VERSION'] = pdk_puppet_version
        end

        # Note that there is no guarantee that the main branch of puppet is compatible with the PDK under test
        # so we can only test that the validate command is using the expected puppet gem location
        describe command('pdk validate --puppet-dev') do
          its(:stderr) { is_expected.to match(%r{Using Puppet file://}i) }
        end

        # Note that there is no guarantee that the main branch of puppet is compatible with the PDK under test
        # so we can only test that the test command is using the expected puppet gem location
        describe command('pdk test unit --puppet-dev') do
          its(:stderr) { is_expected.to match(%r{Using Puppet file://}i) }
        end
      end
    end
  end
end
