require 'spec_helper'
require 'pdk/validate'

describe 'Running `pdk validate` in a module' do
  subject { PDK::CLI.instance_variable_get(:@validate_cmd) }

  include_context :validators
  let(:validator_names) { validators.map(&:name).join(', ') }
  let(:validator_success) { { exit_code: 0, stdout: 'success', stderr: '' } }

  before(:each) do
    allow(PDK::Util::Bundler).to receive(:ensure_bundle!)
  end

  context 'when no arguments or options are provided' do
    it 'invokes each validator with no report and no options and exits zero' do
      validators.each do |validator|
        expect(validator).to receive(:invoke).with(instance_of(PDK::Report), {}).and_return(0)
      end

      expect(logger).to receive(:info).with('Running all available validators...')

      expect {
        PDK::CLI.run(['validate'])
      }.to raise_error(SystemExit) { |error|
        expect(error.status).to eq(0)
      }
    end
  end

  context 'when the --list option is provided' do
    it 'lists all of the available validators and exits zero' do
      expect(logger).to receive(:info).with("Available validators: #{validator_names}")

      expect {
        PDK::CLI.run(['validate', '--list'])
      }.to raise_error(SystemExit) { |error|
        expect(error.status).to eq(0)
      }
    end
  end

  context 'when a single validator is provided as an argument' do
    let(:validator) { PDK::Validate::Metadata }

    it 'only invokes the given validator and exits zero' do
      expect(validator).to receive(:invoke).with(instance_of(PDK::Report), {}).and_return(0)

      validators.reject { |r| r == validator }.each do |v|
        expect(v).not_to receive(:invoke)
      end

      expect {
        PDK::CLI.run(%w[validate metadata])
      }.to raise_error(SystemExit) { |error|
        expect(error.status).to eq(0)
      }
    end
  end

  context 'when multiple known validators are given as arguments' do
    let(:invoked_validators) do
      [
        PDK::Validate::PuppetValidator,
        PDK::Validate::Metadata,
      ]
    end

    it 'invokes each given validator and exits zero' do
      invoked_validators.each do |validator|
        expect(validator).to receive(:invoke).with(instance_of(PDK::Report), {}).and_return(0)
      end

      (validators | invoked_validators).each do |validator|
        expect(validator).not_to receive(:invoke)
      end

      expect {
        PDK::CLI.run(['validate', 'puppet,metadata'])
      }.to raise_error(SystemExit) { |error|
        expect(error.status).to eq(0)
      }
    end
  end

  context 'when unknown validators are given as arguments' do
    let(:validator) { PDK::Validate::PuppetValidator }

    it 'warns about unknown validators, invokes known validators, and exits zero' do
      expect(logger).to receive(:warn).with("Unknown validator 'bad-val'. Available validators: #{validator_names}")
      expect(validator).to receive(:invoke).with(instance_of(PDK::Report), {}).and_return(0)

      expect {
        PDK::CLI.run(['validate', 'puppet,bad-val'])
      }.to raise_error(SystemExit) { |error|
        expect(error.status).to eq(0)
      }
    end
  end

  context 'when targets are provided as arguments' do
    let(:validator) { PDK::Validate::Metadata }

    it 'invokes the specified validator with the target as an option' do
      expect(validator).to receive(:invoke).with(instance_of(PDK::Report), targets: ['lib/', 'manifests/']).and_return(0)

      expect {
        PDK::CLI.run(['validate', 'metadata', 'lib/', 'manifests/'])
      }.to raise_error(SystemExit) { |error|
        expect(error.status).to eq(0)
      }
    end
  end

  context 'when targets are provided as arguments and no validators are specified' do
    it 'invokes all validators with the target as an option' do
      validators.each do |validator|
        expect(validator).to receive(:invoke).with(instance_of(PDK::Report), targets: ['lib/', 'manifests/']).and_return(0)
      end

      expect(logger).to receive(:info).with('Running all available validators...')

      expect {
        PDK::CLI.run(['validate', 'lib/', 'manifests/'])
      }.to raise_error(SystemExit) { |error|
        expect(error.status).to eq(0)
      }
    end
  end
end
