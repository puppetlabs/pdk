require 'spec_helper'
require 'pdk/cli'

def deprecated_runtime?
  Gem::Version.new(RbConfig::CONFIG['ruby_version']) < Gem::Version.new('2.4.0')
end

describe PDK::CLI do
  context 'when invoking help' do
    it 'outputs basic help' do
      expect($stdout).to receive(:puts).with(a_string_matching(/NAME.*USAGE.*DESCRIPTION.*COMMANDS.*OPTIONS/m))

      expect { described_class.run(['--help']) }.to exit_zero
    end
  end

  context 'when invoked by Ruby < 2.4.0', if: deprecated_runtime? do
    before do
      allow($stdout).to receive(:puts)
    end

    it 'informs the user of the upcoming Ruby deprecation' do
      expect(logger).to receive(:info).with(
        text: a_string_matching(/ruby versions older than/i),
        wrap: true,
      )

      described_class.run([])
    end
  end

  context 'when invoked by Ruby >= 2.4.0', unless: deprecated_runtime? do
    before do
      allow($stdout).to receive(:puts)
    end

    it 'does not inform the user of an upcoming Ruby deprecation' do
      expect(logger).not_to receive(:info).with(
        text: a_string_matching(/ruby versions older than/i),
        wrap: true,
      )

      described_class.run([])
    end
  end

  context 'analytics opt-out prompt' do
    before do
      # Temporarily bypass suite-wide analytics disable
      allow(PDK::Util::Env).to receive(:[]).and_call_original
      allow(PDK::Util::Env).to receive(:[]).with('PDK_ANALYTICS_CONFIG').and_return(nil)
      allow(PDK::Util::Env).to receive(:[]).with('PDK_DISABLE_ANALYTICS').and_return(nil)

      # Suppress output
      allow($stdout).to receive(:puts).with(anything)
    end

    context 'when analytics config does not yet exist' do
      before do
        allow(PDK::Config).to receive(:analytics_config_exist?).and_return(false)
      end

      it 'prompts the user about analytics config' do
        expect(PDK::Config).to receive(:analytics_config_interview!)

        expect { described_class.run(['--version']) }.to exit_zero
      end

      context 'when PDK_DISABLE_ANALYTICS is set' do
        before do
          allow(PDK::Util::Env).to receive(:[]).with('PDK_DISABLE_ANALYTICS').and_return('true')
        end

        it 'does not prompt the user about analytics config' do
          expect(PDK::Config).not_to receive(:analytics_config_interview!)

          expect { described_class.run(['--version']) }.to exit_zero
        end
      end
    end

    context 'when analytics config already exists' do
      before do
        allow(PDK::Config).to receive(:analytics_config_exist?).and_return(true)
      end

      it 'does not prompt the user about analytics config' do
        expect(PDK::Config).not_to receive(:analytics_config_interview!)

        expect { described_class.run(['--version']) }.to exit_zero
      end
    end
  end

  ['validate', 'test unit', 'bundle'].each do |command|
    context "when #{command} command used but not in a module folder" do
      include_context 'run outside module'

      it 'informs the user that this is not a module folder' do
        expect(logger).to receive(:error).with(a_string_matching(/(no metadata\.json found|only be run from inside a valid module)/i))

        expect { described_class.run(command.split) }.to exit_nonzero
      end
    end
  end

  context 'when provided an invalid report format' do
    it 'informs the user and exits' do
      expect(logger).to receive(:error).with(a_string_matching(/'non_existant_format'.*valid report format/))

      expect { described_class.run(['--format', 'non_existant_format']) }.to exit_nonzero
    end
  end

  context 'when provided a valid report format' do
    it 'does not exit early with an error' do
      expect(logger).not_to receive(:fatal).with(a_string_matching(/valid report format/))
      allow($stdout).to receive(:puts).with(anything)

      described_class.run(['--format', 'text'])
    end
  end

  context 'when not provided any report formats' do
    it 'does not exit early with an error' do
      expect(logger).not_to receive(:fatal).with(a_string_matching(/valid report format/))
      allow($stdout).to receive(:puts).with(anything)

      described_class.run([])
    end
  end

  context 'when provided an invalid subcommand' do
    it 'submits an event to analytics' do
      expect(analytics).to receive(:event).with(
        'CLI', 'invalid command', label: 'test acceptance --an-opt redacted redacted'
      )

      expect do
        described_class.run(['test', 'acceptance', '--an-opt', 'opt-value', 'some_arg'])
      end.to exit_nonzero.and output.to_stderr
    end
  end
end
