require 'spec_helper'
require 'pdk/cli'

describe 'Running `pdk validate` in a module' do
  subject { PDK::CLI.instance_variable_get(:@validate_cmd) }

  let(:pretty_validator_names) { PDK::Validate.validator_names.join(', ') }
  let(:report) { instance_double(PDK::Report).as_null_object }
  let(:ruby_version) { PDK_VERSION[:latest][:ruby] }
  let(:puppet_version) { PDK_VERSION[:latest][:full] }
  let(:module_path) { '/path/to/testmodule' }
  let(:context) { PDK::Context::Module.new(module_path, module_path) }

  before do
    allow(PDK::CLI::Util).to receive(:puppet_from_opts_or_env).and_return(ruby_version:, gemset: { puppet: puppet_version })
    allow(PDK::Util::RubyVersion).to receive(:use)
    allow(PDK::Util::Bundler).to receive(:ensure_bundle!).with(hash_including(:puppet))

    allow(PDK).to receive(:context).and_return(context)
    allow(PDK::Util).to receive(:module_pdk_version).and_return(PDK::VERSION)

    allow(PDK::Validate).to receive(:invoke_validators_by_name).and_return([0, report])
  end

  context 'when no arguments or options are provided' do
    it 'invokes each validator with no report and no options and exits zero' do
      expect(PDK::Validate).to receive(:invoke_validators_by_name).with(
        PDK::Context::AbstractContext,
        PDK::Validate.validator_names,
        false,
        hash_including(puppet: puppet_version)
      ).and_return([0, report])

      expect(logger).to receive(:info).with('Running all available validators...')

      expect { PDK::CLI.run(['validate']) }.to exit_zero
    end

    context 'with --parallel' do
      it 'invokes each validator with no report and no options and exits zero' do
        expect(PDK::Validate).to receive(:invoke_validators_by_name).with(
          PDK::Context::AbstractContext,
          PDK::Validate.validator_names,
          true,
          hash_including(puppet: puppet_version)
        ).and_return([0, report])

        expect(logger).to receive(:info).with('Running all available validators...')

        expect { PDK::CLI.run(['validate', '--parallel']) }.to exit_zero
      end
    end
  end

  context 'when the --list option is provided' do
    it 'lists all of the available validators and exits zero' do
      expect(logger).to receive(:info).with("Available validators: #{pretty_validator_names}")

      expect { PDK::CLI.run(['validate', '--list']) }.to exit_zero
    end
  end

  context 'when a single validator is provided as an argument' do
    it 'only invokes the given validator and exits zero' do
      expect(PDK::Validate).to receive(:invoke_validators_by_name).with(
        PDK::Context::AbstractContext,
        ['metadata'],
        false,
        hash_including(puppet: puppet_version)
      ).and_return([0, report])

      expect { PDK::CLI.run(['validate', 'metadata']) }.to exit_zero
    end
  end

  context 'when multiple known validators are given as arguments' do
    let(:invoked_validators) { ['metadata', 'puppet'] }

    it 'invokes each given validator and exits zero' do
      expect(PDK::Validate).to receive(:invoke_validators_by_name).with(
        PDK::Context::AbstractContext,
        invoked_validators, false, hash_including(puppet: puppet_version)
      ).and_return([0, report])

      expect { PDK::CLI.run(['validate', 'puppet,metadata']) }.to exit_zero
    end
  end

  context 'when unknown validators are given as arguments' do
    let(:invoked_validators) { ['puppet'] }

    it 'warns about unknown validators, invokes known validators, and exits zero' do
      expect(logger).to receive(:warn).with(/Unknown validator 'bad-val'. Available validators: #{pretty_validator_names}/i)
      expect(PDK::Validate).to receive(:invoke_validators_by_name).with(
        PDK::Context::AbstractContext,
        invoked_validators,
        false,
        hash_including(puppet: puppet_version)
      ).and_return([0, report])

      expect { PDK::CLI.run(['validate', 'puppet,bad-val']) }.to exit_zero
    end
  end

  context 'when targets are provided as arguments' do
    let(:invoked_validators) { ['metadata'] }

    it 'invokes the specified validator with the target as an option' do
      expect(PDK::Validate).to receive(:invoke_validators_by_name).with(
        PDK::Context::AbstractContext,
        invoked_validators,
        false,
        hash_including(puppet: puppet_version, targets: ['lib/', 'manifests/'])
      ).and_return([0, report])

      expect { PDK::CLI.run(['validate', 'metadata', 'lib/', 'manifests/']) }.to exit_zero
    end
  end

  context 'when targets are provided as arguments and no validators are specified' do
    let(:invoked_validators) { PDK::Validate.validator_names }

    it 'invokes all validators with the target as an option' do
      expect(PDK::Validate).to receive(:invoke_validators_by_name).with(
        PDK::Context::AbstractContext,
        invoked_validators,
        false,
        hash_including(puppet: puppet_version, targets: ['lib/', 'manifests/'])
      ).and_return([0, report])

      expect(logger).to receive(:info).with('Running all available validators...')

      expect { PDK::CLI.run(['validate', 'lib/', 'manifests/']) }.to exit_zero
    end
  end

  context 'when no report formats are specified' do
    it 'reports to stdout as text' do
      expect(report).to receive(:write_text).with($stdout)
      expect(report).not_to receive(:write_junit)

      expect { PDK::CLI.run(['validate']) }.to exit_zero
    end
  end

  context 'when a report format is specified' do
    it 'reports to stdout as the specified format' do
      expect(report).to receive(:write_junit).with($stdout)
      expect(report).not_to receive(:write_text)

      expect { PDK::CLI.run(['validate', '--format', 'junit']) }.to exit_zero
    end
  end

  context 'when multiple report formats are specified' do
    it 'reports to each target as the specified format' do
      expect(report).to receive(:write_text).with($stderr)
      expect(report).to receive(:write_text).with($stdout)
      expect(report).to receive(:write_junit).with('testfile.xml')

      expect do
        PDK::CLI.run(['validate', '--format', 'text:stderr', '--format', 'junit:testfile.xml', '--format', 'text'])
      end.to exit_zero
    end
  end

  context 'with --puppet-dev' do
    let(:puppet_env) do
      {
        ruby_version:,
        gemset: { puppet: 'file://path/to/puppet' }
      }
    end

    before do
      allow(PDK::CLI::Util).to receive(:puppet_from_opts_or_env).with(hash_including('puppet-dev': true)).and_return(puppet_env)
      allow(PDK::Util::PuppetVersion).to receive(:fetch_puppet_dev).and_return(nil)
    end

    it 'activates puppet github source' do
      expect(PDK::Util::Bundler).to receive(:ensure_bundle!).with(puppet_env[:gemset])

      expect do
        PDK::CLI.run(['validate', '--puppet-dev'])
      end.to exit_zero
    end

    it 'activates resolved ruby version' do
      expect(PDK::Util::RubyVersion).to receive(:use).with(puppet_env[:ruby_version])

      expect do
        PDK::CLI.run(['validate', '--puppet-dev'])
      end.to exit_zero
    end
  end

  context 'with both --puppet-version and --puppet-dev' do
    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(/cannot specify.*--puppet-dev.*and.*--puppet-version/i))

      expect do
        PDK::CLI.run(['validate', '--puppet-version', '4.10.10', '--puppet-dev'])
      end.to exit_nonzero
    end
  end

  context 'with --puppet-version' do
    let(:puppet_version) { PDK_VERSION[:lts][:ruby] }
    let(:puppet_env) do
      {
        ruby_version:,
        gemset: { puppet: PDK_VERSION[:latest][:full] }
      }
    end

    before do
      allow(PDK::CLI::Util).to receive(:puppet_from_opts_or_env).with(hash_including('puppet-version': puppet_version)).and_return(puppet_env)
    end

    it 'activates resolved puppet version' do
      expect(PDK::Util::Bundler).to receive(:ensure_bundle!).with(puppet_env[:gemset])

      expect do
        PDK::CLI.run(['validate', "--puppet-version=#{puppet_version}"])
      end.to exit_zero
    end

    it 'activates resolved ruby version' do
      expect(PDK::Util::RubyVersion).to receive(:use).with(puppet_env[:ruby_version])

      expect do
        PDK::CLI.run(['validate', "--puppet-version=#{puppet_version}"])
      end.to exit_zero
    end
  end
end
