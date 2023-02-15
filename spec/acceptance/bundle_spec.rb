require 'spec_helper_acceptance'

class IO
  def expects(expected)
    combined_output = ''

    loop do
      rs, = IO.select([self], [], [], 10)

      next if rs.nil?
      next unless (r = rs[0])

      data = r.sysread(1024)
      combined_output << data

      if expected.match?(combined_output) && !r.ready?
        yield combined_output
        break
      end
    end
  rescue EOFError
    nil
  end
end

describe 'pdk bundle' do
  context 'in a new module' do
    include_context 'in a new module', 'bundle'

    before(:all) do
      File.open(File.join('manifests', 'init.pp'), 'w') do |f|
        f.puts '$foo = "bar"'
      end
    end

    describe command('pdk bundle env') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to match(%r{## Environment}) }
    end

    # This test has been scoped to only execute when the following conditions are true
    # * We are not on a windows platform
    # * The current active ruby version is lower than 2.7
    # As of today, it does not seem possible (within reason) to properly send data to the processes write stream when running on ruby 2.7.
    # This causes an issue where the tests will hang indefinitely when we try to retrieve output (r.gets) from
    # the process because there is nothing there to retrieve.
    # After a short discussion internally we decided to scope this test especially as this feature may change in the PDK
    # in coming releases.
    context 'when running an interactive command' do
      it 'works interactively', if: !Gem.win_platform? && Gem::Version.new(PDK::Util::RubyVersion.active_ruby_version) < Gem::Version.new('2.7.0') do
        command = 'pdk bundle exec irb -f --echo --prompt simple'

        require 'pty'
        PTY.spawn(command) do |r, w, _pid|
          # Test that the startup message is displayed
          startup_message = r.gets
          expect(startup_message).to match(%r{pdk \(INFO\): Using Ruby}im)
          r.gets

          # Issue a command and consume the output
          w.puts 'puts __dir__'
          r.gets

          # Test that the output is displayed
          dir = r.gets
          expect(dir).to match(%r{bundle}im)
        end
      end
    end

    context 'when running in a subdirectory of the module root' do
      before(:all) do
        Dir.chdir('manifests')
      end

      after(:all) do
        Dir.chdir('..')
      end

      describe command('pdk bundle exec puppet-lint init.pp') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(%r{double quoted string}im) }
      end
    end

    context 'when there is an invalid Gemfile' do
      before(:all) do
        FileUtils.mv('Gemfile', 'Gemfile.old', force: true)
        File.open('Gemfile', 'w') do |f|
          f.puts 'not a Gemfile'
        end
      end

      after(:all) do
        FileUtils.mv('Gemfile.old', 'Gemfile', force: true)
      end

      describe command('pdk bundle env') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stderr) { is_expected.to match(%r{error parsing `gemfile`}i) }
      end
    end
  end
end
