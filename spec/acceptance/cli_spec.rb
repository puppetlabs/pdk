require 'spec_helper_acceptance'

describe 'Basic usage of the CLI' do
  context 'when the --help options is used' do
    let(:path_to_pdk) do
      posix_path = 'bundle exec pdk'
      windows_path = '/cygdrive/c/Program\ Files/Puppet\ Labs/DevelopmentKit/bin/pdk.bat'
      return posix_path if ENV['BEAKER_TESTMODE'] == 'local'
      if workstation['platform'] =~ /windows/
        windows_path
      else
        posix_path
      end
    end
    let(:help_output) { shell_ex("#{path_to_pdk} --help") }

    it 'displays help text on stdout' do
      expect(help_output.stdout).to match(/NAME.*USAGE.*DESCRIPTION.*COMMANDS.*OPTIONS/m)
    end

    it 'has an empty stderr' do
      expect(help_output.stderr).to eq('')
    end
  end
end
