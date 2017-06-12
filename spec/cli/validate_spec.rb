require 'spec_helper'
require 'pdk/validate'

describe "Running `pdk validate` in a module" do
  subject { PDK::CLI.instance_variable_get(:@validate_cmd) }
  include_context :validators
  let(:validator_names) { validators.map(&:name).join(', ') }

  context 'when no arguments or options are provided' do
    it 'should invoke each validator with no report and no options' do
      validators.each do |validator|
        expect(validator).to receive(:invoke).with({})
      end
      expect(logger).to receive(:info).with('Running all available validators...')

      expect {
        PDK::CLI.run(['validate'])
      }.not_to raise_error
    end
  end

  context 'when the --list option is provided' do
    it 'should list all of the available validators and exit' do
      expect(logger).to receive(:info).with("Available validators: #{validator_names}")

      expect {
        PDK::CLI.run(['validate', '--list'])
      }.to raise_error(SystemExit) { |error|
        expect(error.status).to eq(0)
      }
    end
  end

  context 'when validators are provided as arguments' do
    it 'should only invoke a single validator when only one is provided' do
      expect(PDK::Validate::Metadata).to receive(:invoke).with({})

      validators.reject { |r| r == PDK::Validate::Metadata }.each do |validator|
        expect(validator).not_to receive(:invoke)
      end

      expect {
        PDK::CLI.run(['validate', 'metadata'])
      }.not_to raise_error
    end

    it 'should invoke each provided validator when multiple are provided' do
      invoked_validators = [
        PDK::Validate::PuppetValidator,
        PDK::Validate::Metadata,
      ]

      invoked_validators.each do |validator|
        expect(validator).to receive(:invoke).with({})
      end

      (validators | invoked_validators).each do |validator|
        expect(validator).not_to receive(:invoke)
      end

      expect {
        PDK::CLI.run(['validate', 'puppet,metadata'])
      }.not_to raise_error
    end

    it 'should warn about unknown validators' do
      expect(logger).to receive(:warn).with("Unknown validator 'bad-val'. Available validators: #{validator_names}")
      expect(PDK::Validate::PuppetValidator).to receive(:invoke).with({})

      expect {
        PDK::CLI.run(['validate', 'puppet,bad-val'])
      }.not_to raise_error
    end

    context 'when targets are provided as arguments' do
      pending "`validate` not implemented yet"
      it 'should invoke the specified validator with the target as an option' do
        expect(PDK::Validate::Metadata).to receive(:invoke).with({:targets => ['lib/', 'manifests/']})

        expect {
          PDK::CLI.run(['validate', 'metadata', 'lib/', 'manifests/'])
        }.not_to raise_error
      end
    end
  end

  context 'when targets are provided as arguments and no validators are specified' do
    pending "`validate` not implemented yet"
    it 'should invoke all validators with the target as an option' do
      validators.each do |validator|
        expect(validator).to receive(:invoke).with({:targets => ['lib/', 'manifests/']})
      end
      expect(logger).to receive(:info).with('Running all available validators...')

      expect {
        PDK::CLI.run(['validate', 'lib/', 'manifests/'])
      }.not_to raise_error
    end
  end
end
