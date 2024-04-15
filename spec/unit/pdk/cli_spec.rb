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
        wrap: true
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
        wrap: true
      )

      described_class.run([])
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
end
