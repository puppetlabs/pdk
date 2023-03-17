require 'spec_helper'
require 'pdk/util/bundler'

RSpec.describe PDK::Util::Bundler do
  describe 'class methods' do
    # Default to non-package install
    include_context 'not packaged install'

    let(:gemfile) { '/Gemfile' }
    let(:gemfile_lock) { "#{gemfile}.lock" }
    let(:bundle_helper) do
      instance_double(PDK::Util::Bundler::BundleHelper, gemfile: gemfile, gemfile?: true, gemfile_lock: gemfile_lock)
    end

    before(:each) do
      # Allow us to mock/stub/expect calls to the internal bundle helper.
      allow(PDK::Util::Bundler::BundleHelper).to receive(:new).and_return(bundle_helper)
      allow(PDK::Util::Filesystem).to receive(:mv).with(gemfile_lock, anything)
      allow(PDK::Util::Filesystem).to receive(:mv).with(anything, gemfile_lock, force: true)
    end

    describe '.ensure_bundle!' do
      before(:each) do
        # Avoid the early short-circuit this method implements unless we are
        # explicitly unit testing that method.
        allow(described_class).to receive(:already_bundled?).and_return(false)
      end

      context 'when there is no Gemfile' do
        before(:each) do
          allow(bundle_helper).to receive(:gemfile?).and_return(false)
        end

        it 'does nothing' do
          expect(bundle_helper).not_to receive(:locked?)
          expect(bundle_helper).not_to receive(:installed?)
          expect(bundle_helper).not_to receive(:lock!)
          expect(bundle_helper).not_to receive(:update_lock!)
          expect(bundle_helper).not_to receive(:install!)

          described_class.ensure_bundle!
        end
      end

      context 'when given Gemfile has already been bundled' do
        before(:each) do
          allow(described_class).to receive(:already_bundled?).and_return(true)
        end

        it 'does nothing' do
          expect(bundle_helper).not_to receive(:locked?)
          expect(bundle_helper).not_to receive(:installed?)
          expect(bundle_helper).not_to receive(:lock!)
          expect(bundle_helper).not_to receive(:update_lock!)
          expect(bundle_helper).not_to receive(:install!)

          described_class.ensure_bundle!
        end
      end

      context 'when there is an existing Gemfile.lock' do
        before(:each) do
          allow(bundle_helper).to receive(:locked?).and_return(true)
          allow(bundle_helper).to receive(:installed?).and_return(true)
        end

        it 'updates Gemfile.lock using default sources' do
          expect(bundle_helper).to receive(:update_lock!).with(hash_including(local: true))

          described_class.ensure_bundle!
        end

        context 'when part of a packaged installation' do
          include_context 'packaged install'

          it 'updates Gemfile.lock using local gems' do
            expect(bundle_helper).to receive(:update_lock!).with(hash_including(local: true))

            described_class.ensure_bundle!
          end
        end
      end

      context 'when there is no Gemfile.lock' do
        before(:each) do
          allow(bundle_helper).to receive(:locked?).and_return(false)
          allow(bundle_helper).to receive(:installed?).and_return(true)
          allow(bundle_helper).to receive(:update_lock!).with(any_args)
        end

        it 'generates Gemfile.lock' do
          expect(bundle_helper).to receive(:lock!)

          described_class.ensure_bundle!
        end
      end

      context 'when there are missing gems' do
        before(:each) do
          allow(bundle_helper).to receive(:locked?).and_return(true)
          allow(bundle_helper).to receive(:update_lock!)

          allow(bundle_helper).to receive(:installed?).and_return(false)
        end

        it 'installs missing gems' do
          expect(bundle_helper).to receive(:install!)

          described_class.ensure_bundle!
        end
      end

      context 'when there are no missing gems' do
        before(:each) do
          allow(bundle_helper).to receive(:locked?).and_return(true)
          allow(bundle_helper).to receive(:update_lock!)

          allow(bundle_helper).to receive(:installed?).and_return(true)
        end

        it 'does not try to install missing gems' do
          expect(bundle_helper).not_to receive(:install!)

          described_class.ensure_bundle!
        end
      end

      context 'when everything goes well' do
        before(:each) do
          allow(bundle_helper).to receive(:locked?).and_return(true)
          allow(bundle_helper).to receive(:update_lock!)
          allow(bundle_helper).to receive(:installed?).and_return(true)
        end

        it 'marks gemfile as bundled' do
          expect(described_class).to receive(:mark_as_bundled!).with(bundle_helper.gemfile, anything)

          described_class.ensure_bundle!
        end

        context 'when overriding gems' do
          let(:overrides) do
            { puppet: nil }
          end

          it 'marks gemfile/overrides combo as bundled' do
            expect(described_class).to receive(:mark_as_bundled!).with(bundle_helper.gemfile, overrides)

            described_class.ensure_bundle!(overrides)
          end
        end
      end
    end

    describe '.ensure_binstubs!' do
      let(:gems) { %w[apple banana mango] }

      it 'delegates to BundleHelper.binstubs!' do
        expect(bundle_helper).to receive(:binstubs!).with(gems)

        described_class.ensure_binstubs!(*gems)
      end
    end

    describe '.already_bundled?' do
      let(:bundled_gemfile) { '/already/bundled/Gemfile' }
      let(:unbundled_gemfile) { '/to/be/bundled/Gemfile' }
      let(:overrides) { {} }

      before(:each) do
        described_class.mark_as_bundled!(bundled_gemfile, overrides)
      end

      it 'returns false for unbundled Gemfile' do
        expect(described_class.already_bundled?(unbundled_gemfile, overrides)).to be false
      end

      it 'returns true for already bundled Gemfile' do
        expect(described_class.already_bundled?(bundled_gemfile, overrides)).to be true
      end

      context 'with gem overrides' do
        let(:overrides) do
          { gem1: '1.2.3', gem2: '4.5.6' }
        end

        before(:each) do
          described_class.mark_as_bundled!(bundled_gemfile, overrides)
        end

        it 'returns false for unbundled Gemfile' do
          expect(described_class.already_bundled?(unbundled_gemfile, overrides)).to be false
        end

        it 'returns false for already bundled Gemfile with additional overrides' do
          expect(described_class.already_bundled?(unbundled_gemfile, overrides.merge(gem3: '2.2.2'))).to be false
        end

        it 'returns true for already bundled Gemfile' do
          expect(described_class.already_bundled?(bundled_gemfile, overrides)).to be true
        end
      end
    end

    describe '.mark_as_bundled!' do
      let(:gemfile) { '/newly/bundled/Gemfile' }
      let(:overrides) { {} }

      it 'changes response of already_bundled? from false to true' do
        expect {
          described_class.mark_as_bundled!(gemfile, overrides)
        }.to change {
          described_class.already_bundled?(gemfile, overrides)
        }.from(false).to(true)
      end

      context 'with gem overrides' do
        let(:overrides) do
          { gem1: '1.2.3', gem2: '4.5.6' }
        end

        it 'changes response of already_bundled? from false to true' do
          expect {
            described_class.mark_as_bundled!(gemfile, overrides)
          }.to change {
            described_class.already_bundled?(gemfile, overrides)
          }.from(false).to(true)
        end
      end
    end
  end

  describe PDK::Util::Bundler::BundleHelper do
    def command_double(result, overrides = {})
      instance_double(PDK::CLI::Exec::Command, {
        'execute!' => result,
        'context=' => true,
        'add_spinner' => true,
        'environment' => {},
        'update_environment' => {},
      }.merge(overrides))
    end

    def allow_command(argv, result = nil)
      result ||= { exit_code: 0, stdout: '', stderr: '' }

      cmd = command_double(result)

      allow(PDK::CLI::Exec::Command).to receive(:new).with(*argv).and_return(cmd)

      cmd
    end

    def expect_command(argv, result = nil, spinner_message = nil)
      result ||= { exit_code: 0, stdout: '', stderr: '' }

      cmd = command_double(result)

      if spinner_message
        expect(cmd).to receive(:add_spinner).with(spinner_message, any_args)
      end

      # TODO: it would be nice to update 'expect_command' to allow arguments in any order
      expect(PDK::CLI::Exec::Command).to receive(:new).with(*argv).and_return(cmd)

      cmd
    end

    def bundle_regex
      %r{bundle(\.bat)?$}
    end

    # Default to non-package install
    include_context 'not packaged install'

    let(:instance) { described_class.new }

    before(:each) do
      # Doesn't matter where this is since all the execs get mocked.
      allow(PDK::Util).to receive(:module_root).and_return('/')

      allow(logger).to receive(:debug?).and_return(false)
    end

    describe '#gemfile' do
      subject { instance.gemfile }

      let(:gemfile_path) { '/Gemfile' }

      context 'when Gemfile exists' do
        before(:each) do
          allow(PDK::Util).to receive(:find_upwards).with(%r{Gemfile$}).and_return(gemfile_path)
        end

        it { is_expected.to be gemfile_path }
      end

      context 'when Gemfile does not exist' do
        before(:each) do
          allow(PDK::Util).to receive(:find_upwards).with(%r{Gemfile$}).and_return(nil)
        end

        it { is_expected.to be nil }
      end
    end

    describe '#gemfile?' do
      subject { instance.gemfile? }

      context 'when Gemfile exists' do
        before(:each) do
          allow(PDK::Util).to receive(:find_upwards).with(%r{Gemfile$}).and_return('/Gemfile')
        end

        it { is_expected.to be true }
      end

      context 'when Gemfile does not exist' do
        before(:each) do
          allow(PDK::Util).to receive(:find_upwards).with(%r{Gemfile$}).and_return(nil)
        end

        it { is_expected.to be false }
      end
    end

    describe '#locked?' do
      subject { instance.locked? }

      context 'when Gemfile.lock exists' do
        before(:each) do
          allow(PDK::Util).to receive(:find_upwards).with(%r{Gemfile$}).and_return('/Gemfile')
          allow(PDK::Util::Filesystem).to receive(:file?).with(%r{Gemfile\.lock$}).and_return(true)
        end

        it { is_expected.to be true }
      end

      context 'when Gemfile.lock does not exist' do
        before(:each) do
          allow(PDK::Util).to receive(:find_upwards).with(%r{Gemfile$}).and_return(nil)
          allow(PDK::Util::Filesystem).to receive(:file?).with(%r{Gemfile\.lock$}).and_return(false)
        end

        it { is_expected.to be false }
      end
    end

    describe '#installed?' do
      let(:gemfile) { '/Gemfile' }

      before(:each) do
        allow(instance).to receive(:gemfile).and_return(gemfile)
      end

      it 'invokes `bundle check`' do
        expect_command([bundle_regex, 'check', "--gemfile=#{gemfile}", '--dry-run'], exit_code: 0)

        instance.installed?
      end

      it 'returns true if `bundle check` exits zero' do
        allow_command([bundle_regex, 'check', "--gemfile=#{gemfile}", '--dry-run'], exit_code: 0)

        expect(instance.installed?).to be true
      end

      context 'when `bundle check` exits non-zero' do
        before(:each) do
          allow_command([bundle_regex, 'check', "--gemfile=#{gemfile}", '--dry-run'], exit_code: 1, stderr: 'this is an error message')
        end

        it 'returns false' do
          expect(instance.installed?).to be false
        end
      end

      context 'packaged install' do
        include_context 'packaged install'

        it 'invokes `bundle check` without --path option' do
          expect_command([bundle_regex, 'check', "--gemfile=#{gemfile}", '--dry-run'], exit_code: 0)

          instance.installed?
        end
      end

      context 'with gem overrides' do
        let(:overrides) { { puppet: '1.2.3' } }

        it 'updates env before invoking `bundle check`' do
          cmd_double = allow_command([bundle_regex, 'check', "--gemfile=#{gemfile}", '--dry-run'], exit_code: 0)

          expect(cmd_double).to receive(:update_environment).with(hash_including('PUPPET_GEM_VERSION' => '1.2.3'))

          instance.installed?(overrides)
        end
      end
    end

    describe '#lock!' do
      before(:each) do
        allow_command([bundle_regex, 'lock', %r{--lockfile}, '--update', 'json', '--local'], exit_code: 0)
      end

      it 'invokes `bundle lock`' do
        expect_command([bundle_regex, 'lock'], exit_code: 0)

        instance.lock!
      end

      it 'returns true if `bundle lock` exits zero' do
        allow_command([bundle_regex, 'lock'], exit_code: 0)

        expect(instance.lock!).to be true
      end

      it 'invokes #update_lock! to re-resolve json dependency locally' do
        allow_command([bundle_regex, 'lock'], exit_code: 0)

        expect(instance).to receive(:update_lock!).with(hash_including(only: hash_including(:json), local: true)).and_return(true)

        instance.lock!
      end

      context 'when `bundle lock` exits non-zero' do
        before(:each) do
          allow_command([bundle_regex, 'lock'], exit_code: 1, stderr: 'bundle lock error message')
        end

        it 'logs a fatal message with output and raises FatalError' do
          expect(logger).to receive(:fatal).with(%r{bundle lock error message}i)
          expect { instance.lock! }.to raise_error(PDK::CLI::FatalError, %r{unable to resolve}i)
        end
      end

      context 'packaged install' do
        include_context 'packaged install'

        before(:each) do
          # package_cachedir comes from 'packaged install' context
          allow(PDK::Util::Filesystem).to receive(:exist?).with("#{package_cachedir}/Gemfile.lock").and_return(true)
          allow(PDK::Util::RubyVersion).to receive(:active_ruby_version).and_return('2.4.4')
          PDK::Util::RubyVersion.versions.each_key do |ruby_version|
            lockfile = File.join(package_cachedir, "Gemfile-#{ruby_version}.lock")
            allow(PDK::Util::Filesystem).to receive(:exist?).with(lockfile).and_return(true)
          end

          allow(PDK::Util::Filesystem).to receive(:cp)
        end

        it 'copies a Gemfile.lock from vendored location' do
          # package_cachedir comes from 'packaged install' context
          lockfile = File.join(package_cachedir, "Gemfile-#{PDK::Util::RubyVersion.active_ruby_version}.lock")
          expect(PDK::Util::Filesystem).to receive(:cp).with(lockfile, %r{Gemfile\.lock$})

          instance.lock!
        end

        it 'logs a debug message about using vendored Gemfile.lock' do
          expect(logger).to receive(:debug).with(%r{vendored gemfile\.lock}i)

          instance.lock!
        end

        context 'when vendored Gemfile.lock does not exist' do
          before(:each) do
            allow(PDK::Util::Filesystem).to receive(:exist?).with("#{package_cachedir}/Gemfile.lock").and_return(false)
            PDK::Util::RubyVersion.versions.each_key do |ruby_version|
              lockfile = File.join(package_cachedir, "Gemfile-#{ruby_version}.lock")
              allow(PDK::Util::Filesystem).to receive(:exist?).with(lockfile).and_return(false)
            end
          end

          it 'raises FatalError' do
            expect { instance.lock! }.to raise_error(PDK::CLI::FatalError, %r{vendored gemfile\.lock.*not found}i)
          end
        end
      end
    end

    describe '#update_lock!' do
      let(:overrides) { { puppet: '1.2.3' } }
      let(:overridden_gems) { overrides.keys.map(&:to_s) }

      it 'updates env before invoking `bundle lock --update`' do
        cmd_double = allow_command([bundle_regex, 'lock', %r{--lockfile}, '--update'], exit_code: 0)

        expect(cmd_double).to receive(:update_environment).with(hash_including('BUNDLE_GEMFILE'))
        expect(cmd_double).to receive(:update_environment).with(hash_including('PUPPET_GEM_VERSION' => '1.2.3'))

        instance.update_lock!(with: overrides)
      end

      it 'invokes `bundle lock --update`' do
        expect_command([bundle_regex, 'lock', %r{--lockfile}, '--update'], exit_code: 0)

        instance.update_lock!(with: overrides)
      end

      context 'when `bundle lock --update` exits non-zero' do
        before(:each) do
          allow_command([bundle_regex, 'lock', %r{--lockfile}, '--update'], exit_code: 1, stderr: 'bundle lock update error message')
        end

        it 'logs a fatal message with output and raises FatalError' do
          expect(logger).to receive(:fatal).with(%r{bundle lock update error message}i)
          expect { instance.update_lock!(with: overrides) }.to raise_error(PDK::CLI::FatalError, %r{unable to resolve}i)
        end
      end

      context 'with multiple overrides' do
        let(:overrides) { { puppet: '1.2.3', facter: '2.3.4' } }
        let(:expected_environment) do
          {
            'PUPPET_GEM_VERSION' => '1.2.3',
            'FACTER_GEM_VERSION' => '2.3.4',
          }
        end

        it 'includes all gem overrides in the command environment' do
          cmd_double = allow_command([bundle_regex, 'lock', %r{--lockfile}, '--update'], exit_code: 0)

          expect(cmd_double).to receive(:update_environment).with(hash_including(expected_environment))

          instance.update_lock!(with: overrides)
        end
      end

      context 'with local option set' do
        let(:options) { { local: true } }

        it 'includes \'--local\' in `bundle lock --update` invocation' do
          expect_command([bundle_regex, 'lock', %r{--lockfile}, '--update', '--local'], exit_code: 0)

          instance.update_lock!(options.merge(with: overrides))
        end
      end

      context 'with no overrides' do
        let(:overrides) { {} }

        it 'does not update the command environment' do
          cmd_double = allow_command([bundle_regex, 'lock', %r{--lockfile}, '--update'], exit_code: 0)

          expect(cmd_double).to receive(:update_environment).with({})

          instance.update_lock!(with: overrides)
        end
      end
    end

    describe '#install!' do
      let(:gemfile) { '/Gemfile' }
      let(:expected_bundle_install) { [bundle_regex, 'install', "--gemfile=#{gemfile}", '-j4'] }

      before(:each) do
        allow(instance).to receive(:gemfile).and_return(gemfile)
        allow(Gem).to receive(:win_platform?).and_return(false)
        allow(PDK::Util::RubyVersion).to receive(:active_ruby_version).and_return('2.4.4')
      end

      it 'invokes `bundle install`' do
        expect_command(expected_bundle_install, exit_code: 0)

        instance.install!
      end

      it 'returns true if `bundle install` exits zero' do
        allow_command(expected_bundle_install, exit_code: 0)

        expect(instance.install!).to be true
      end

      context 'when `bundle install` exits non-zero' do
        before(:each) do
          allow_command(expected_bundle_install, exit_code: 1, stderr: 'bundle install error message')
        end

        it 'logs a fatal message with output and raises FatalError' do
          expect(logger).to receive(:fatal).with(%r{bundle install error message}i)
          expect { instance.install! }.to raise_error(PDK::CLI::FatalError, %r{unable to install}i)
        end
      end

      context 'packaged install' do
        include_context 'packaged install'

        let(:expected_bundle_install) { [bundle_regex, 'install', "--gemfile=#{gemfile}", '-j4'] }

        it 'invokes `bundle install` without --path option' do
          expect_command(expected_bundle_install, exit_code: 0)

          instance.install!
        end
      end

      context 'with gem overrides' do
        let(:overrides) { { puppet: '1.2.3' } }

        it 'updates env before invoking `bundle install`' do
          cmd_double = allow_command(expected_bundle_install, exit_code: 0)

          expect(cmd_double).to receive(:update_environment).with(hash_including('PUPPET_GEM_VERSION' => '1.2.3'))

          instance.install!(overrides)
        end
      end

      context 'on Windows running older Ruby' do
        let(:expected_bundle_install) { [bundle_regex, 'install', "--gemfile=#{gemfile}"] }

        before(:each) do
          allow(Gem).to receive(:win_platform?).and_return(true)
          allow(PDK::Util::RubyVersion).to receive(:active_ruby_version).and_return('2.1.9')
        end

        it 'invokes `bundle install` without -j4 option' do
          expect_command(expected_bundle_install, exit_code: 0)

          instance.install!
        end
      end
    end

    describe '#binstubs!' do
      let(:gemfile) { '/Gemfile' }
      let(:requested_gems) { %w[rake rspec metadata-json-lint] }

      before(:each) do
        allow(instance).to receive(:gemfile).and_return(gemfile)
        allow(PDK::Util::Filesystem).to receive(:file?).and_return(false)
      end

      it 'invokes `bundle binstubs` with requested gems' do
        expect_command([bundle_regex, 'binstubs', requested_gems, '--force'].flatten, exit_code: 0)

        instance.binstubs!(requested_gems)
      end

      it 'returns true if `bundle install` exits zero' do
        allow_command([bundle_regex, 'binstubs', requested_gems, '--force'].flatten, exit_code: 0)

        expect(instance.binstubs!(requested_gems)).to be true
      end

      context 'when `bundle binstubs` exits non-zero' do
        before(:each) do
          allow_command([bundle_regex, 'binstubs', requested_gems, '--force'].flatten, exit_code: 1, stderr: 'bundle binstubs error message')
        end

        it 'logs a fatal message with output and raises FatalError' do
          expect(logger).to receive(:fatal).with(%r{bundle binstubs error message}i)
          expect { instance.binstubs!(requested_gems) }.to raise_error(PDK::CLI::FatalError, %r{unable to install.*binstubs}i)
        end
      end

      context 'when binstubs for all requested gems are already present' do
        before(:each) do
          requested_gems.each do |gemname|
            allow(PDK::Util::Filesystem).to receive(:file?).with(%r{#{gemname}$}).and_return(true)
          end
        end

        it 'returns true early' do
          expect(PDK::CLI::Exec::Command).not_to receive(:new)

          expect(instance.binstubs!(requested_gems)).to be true
        end
      end
    end
  end
end
