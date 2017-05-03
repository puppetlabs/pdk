require 'spec_helper'

describe PDK::CLI::Validate do
  context 'when no arguments or options are provided' do
    it 'should invoke each validator with no report and no options' do
      [PDK::Validate::Metadata,
       PDK::Validate::PuppetLint,
       PDK::Validate::PuppetParser,
       PDK::Validate::RubyLint].each do |validator|
        expect(validator).to receive(:invoke).with({})
      end
      expect(logger).to receive(:info).with('Running all available validators...')
      PDK::CLI.run(['validate'])
    end
  end

  context 'when the --list option is provided' do
    it 'should list all of the available validators and exit' do
      # TODO: replace this with a real output mechanism
      expect(STDOUT).to receive(:puts).with('Available validators: metadata, puppet-lint, puppet-parser, ruby-lint')

      begin
        PDK::CLI.run(['validate', '--list'])
      rescue SystemExit => e
        expect(e.status).to eq(0)
      end
    end
  end

  context 'when validators are provided as arguments' do
    it 'should only invoke a single validator when only one is provided' do
      expect(PDK::Validate::Metadata).to receive(:invoke).with({})

      [PDK::Validate::PuppetLint,
       PDK::Validate::PuppetParser,
       PDK::Validate::RubyLint].each do |validator|
        expect(validator).not_to receive(:invoke)
      end

      PDK::CLI.run(['validate', 'metadata'])
    end

    it 'should invoke each provided validator when multiple are provided' do
      [PDK::Validate::PuppetLint, PDK::Validate::PuppetParser].each do |validator|
        expect(validator).to receive(:invoke).with({})
      end

      [PDK::Validate::Metadata, PDK::Validate::RubyLint].each do |validator|
        expect(validator).not_to receive(:invoke)
      end

      PDK::CLI.run(['validate', 'puppet-lint,puppet-parser'])
    end

    it 'should warn about unknown validators' do
      expect(logger).to receive(:warn).with('Unknown validator \'bad-val\'. Available validators: metadata, puppet-lint, puppet-parser, ruby-lint')
      expect(PDK::Validate::PuppetLint).to receive(:invoke).with({})

      PDK::CLI.run(['validate', 'puppet-lint,bad-val'])
    end

    context 'when targets are provided as arguments' do
      it 'should invoke the specified validator with the target as an option' do
        expect(PDK::Validate::Metadata).to receive(:invoke).with({:targets => ['lib/', 'manifests/']})

        PDK::CLI.run(['validate', 'metadata', 'lib/', 'manifests/'])
      end
    end
  end

  context 'when targets are provided as arguments and no validators are specified' do
    it 'should invoke all validators with the target as an option' do
      [PDK::Validate::Metadata,
       PDK::Validate::PuppetLint,
       PDK::Validate::PuppetParser,
       PDK::Validate::RubyLint].each do |validator|
        expect(validator).to receive(:invoke).with({:targets => ['lib/', 'manifests/']})
      end
      expect(logger).to receive(:info).with('Running all available validators...')
      PDK::CLI.run(['validate', 'lib/', 'manifests/'])
    end
  end
end
