require 'spec_helper_acceptance'
require 'open3'

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

    context 'when running an interactive command' do
      it 'works interactively' do
        command = 'pdk bundle exec irb -f --echo --prompt simple'
        prompt = %r{>> \Z}m
        exit_command = "exit\n"

        Open3.popen2e(command) do |stdin, stdouterr, _|
          stdouterr.expects(prompt) { |_| stdin.syswrite "require 'date'\n" }
          stdouterr.expects(prompt) { |_| stdin.syswrite "Date.today.year\n" }
          stdouterr.expects(prompt) do |output|
            expect(output).to match(%r{=> #{Date.today.year}}m)
            stdin.syswrite exit_command
          end
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
        if ENV['APPVEYOR']
          # TODO: This is very strange that Appveyor emits the error on STDOUT instead of STDERR
          # For moment switch the expectation based on the APPVEYOR environment variable
          its(:stdout) { is_expected.to match(%r{error parsing `gemfile`}i) }
        else
          its(:stderr) { is_expected.to match(%r{error parsing `gemfile`}i) }
        end
      end
    end
  end
end
