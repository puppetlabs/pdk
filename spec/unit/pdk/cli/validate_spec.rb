# frozen_string_literal: true

require 'spec_helper'
require 'pdk/validate'

describe 'Running `pdk validate` in a module' do
  subject { PDK::CLI.instance_variable_get(:@validate_cmd) }

  include_context :validators
  let(:validator_names) { validators.map(&:name).join(', ') }
  let(:validator_success) { { exit_code: 0, stdout: 'success', stderr: '' } }
  let(:report) { instance_double('PDK::Report').as_null_object }

  before(:each) do
    allow(Dir).to receive(:chdir) { |_dir, &block| block.call }
    allow(PDK::Util::Bundler).to receive(:ensure_bundle!)
    allow(PDK::Util).to receive(:module_root).and_return('/path/to/testmodule')
    allow(PDK::Report).to receive(:new).and_return(report)
  end

  context 'when no arguments or options are provided' do
    it 'invokes each validator with no report and no options and exits zero' do
      expect(validators).to all(receive(:invoke).with(report, {}).and_return(0))

      expect(logger).to receive(:info).with('Running all available validators...')

      expect { PDK::CLI.run(['validate']) }.to exit_zero
    end

    context 'with --parallel' do
      let(:spinner) { instance_double('TTY::Spinner::Multi').as_null_object }

      before(:each) do
        allow(TTY::Spinner::Multi).to receive(:new).and_return(spinner)
      end

      it 'invokes each validator with no report and no options and exits zero' do
        expect(validators).to all(receive(:invoke).and_return(0))

        expect(logger).to receive(:info).with('Running all available validators...')

        expect { PDK::CLI.run(['validate', '--parallel']) }.to exit_zero
      end
    end
  end

  context 'when the --list option is provided' do
    it 'lists all of the available validators and exits zero' do
      expect(logger).to receive(:info).with("Available validators: #{validator_names}")

      expect { PDK::CLI.run(['validate', '--list']) }.to exit_zero
    end
  end

  context 'when a single validator is provided as an argument' do
    let(:validator) { PDK::Validate::MetadataValidator }

    it 'only invokes the given validator and exits zero' do
      expect(validator).to receive(:invoke).with(report, {}).and_return(0)

      validators.reject { |r| r == validator }.each do |v|
        expect(v).not_to receive(:invoke)
      end

      expect { PDK::CLI.run(%w[validate metadata]) }.to exit_zero
    end
  end

  context 'when multiple known validators are given as arguments' do
    let(:invoked_validators) do
      [
        PDK::Validate::PuppetValidator,
        PDK::Validate::MetadataValidator,
      ]
    end

    it 'invokes each given validator and exits zero' do
      expect(invoked_validators).to all(receive(:invoke).with(report, {}).and_return(0))

      (validators | invoked_validators).each do |validator|
        expect(validator).not_to receive(:invoke)
      end

      expect { PDK::CLI.run(['validate', 'puppet,metadata']) }.to exit_zero
    end
  end

  context 'when unknown validators are given as arguments' do
    let(:validator) { PDK::Validate::PuppetValidator }

    it 'warns about unknown validators, invokes known validators, and exits zero' do
      expect(logger).to receive(:warn).with(%r{Unknown validator 'bad-val'. Available validators: #{validator_names}}i)
      expect(validator).to receive(:invoke).with(report, {}).and_return(0)

      expect { PDK::CLI.run(['validate', 'puppet,bad-val']) }.to exit_zero
    end
  end

  context 'when targets are provided as arguments' do
    let(:validator) { PDK::Validate::MetadataValidator }

    it 'invokes the specified validator with the target as an option' do
      expect(validator).to receive(:invoke).with(report, targets: ['lib/', 'manifests/']).and_return(0)

      expect { PDK::CLI.run(['validate', 'metadata', 'lib/', 'manifests/']) }.to exit_zero
    end
  end

  context 'when targets are provided as arguments and no validators are specified' do
    it 'invokes all validators with the target as an option' do
      expect(validators).to all(receive(:invoke).with(report, targets: ['lib/', 'manifests/']).and_return(0))

      expect(logger).to receive(:info).with('Running all available validators...')

      expect { PDK::CLI.run(['validate', 'lib/', 'manifests/']) }.to exit_zero
    end
  end

  context 'when no report formats are specified' do
    it 'reports to stdout as text' do
      expect(validators).to all(receive(:invoke).with(report, {}).and_return(0))
      expect(report).to receive(:write_text).with($stdout)
      expect(report).not_to receive(:write_junit)

      expect { PDK::CLI.run(['validate']) }.to exit_zero
    end
  end

  context 'when a report format is specified' do
    it 'reports to stdout as the specified format' do
      expect(validators).to all(receive(:invoke).with(report, {}).and_return(0))
      expect(report).to receive(:write_junit).with($stdout)
      expect(report).not_to receive(:write_text)

      expect { PDK::CLI.run(['validate', '--format', 'junit']) }.to exit_zero
    end
  end

  context 'when multiple report formats are specified' do
    it 'reports to each target as the specified format' do
      expect(validators).to all(receive(:invoke).with(report, {}).and_return(0))
      expect(report).to receive(:write_text).with($stderr)
      expect(report).to receive(:write_text).with($stdout)
      expect(report).to receive(:write_junit).with('testfile.xml')

      expect {
        PDK::CLI.run(%w[validate --format text:stderr --format junit:testfile.xml --format text])
      }.to exit_zero
    end
  end

  context 'when --puppet-version and --pe-version are specified' do
    before(:each) do
      allow(PDK::Util::PuppetVersion).to receive(:find_gem_for).with('4.10.10').and_return('4.10.10')
      allow(PDK::Util::PuppetVersion).to receive(:from_pe_version).with('2018.1.1').and_return('4.10.10')
    end

    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(%r{both --puppet-version and --pe-version}i))

      expect {
        PDK::CLI.run(%w[validate --puppet-version 4.10.10 --pe-version 2018.1.1])
      }.to exit_nonzero
    end
  end
end
