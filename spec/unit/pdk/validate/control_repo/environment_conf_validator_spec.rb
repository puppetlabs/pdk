require 'spec_helper'
require 'pdk/validate/control_repo/environment_conf_validator'

describe PDK::Validate::ControlRepo::EnvironmentConfValidator do
  let(:validator) { described_class.new(validator_context, validator_options) }
  let(:validator_context) { PDK::Context::ControlRepo.new(Dir.pwd, Dir.pwd) }
  let(:validator_options) { {} }

  describe '.name' do
    subject { validator.name }

    it { is_expected.to eq('environment-conf') }
  end

  describe '.spinner_text' do
    subject(:spinner_text) { validator.spinner_text }

    it { is_expected.to match(/Checking Puppet Environment settings/i) }
  end

  it_behaves_like 'only valid in specified PDK contexts', PDK::Context::ControlRepo

  describe '.validate_target' do
    subject(:return_value) { described_class.new.validate_target(report, target[:name]) }

    let(:report) { PDK::Report.new }

    before do
      [
        target[:name],
        File.join(validator_context.root_path, target[:name])
      ].each do |filename|
        allow(PDK::Util::Filesystem).to receive(:directory?).with(filename).and_return(target.fetch(:directory, false))
        allow(PDK::Util::Filesystem).to receive(:file?).with(filename).and_return(target.fetch(:file, true))
        allow(PDK::Util::Filesystem).to receive(:readable?).with(filename).and_return(target.fetch(:readable, true))
        allow(PDK::Util::Filesystem).to receive(:read_file).with(filename).and_return(target.fetch(:content, ''))
      end
    end

    context 'when a target is provided that is an unreadable file' do
      let(:target) { { name: 'environment.conf', readable: false } }

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with({
                                                     file: target[:name],
                                                     source: validator.name,
                                                     state: :failure,
                                                     severity: 'error',
                                                     message: 'Could not be read.',
                                                   })
        expect(return_value).to eq(1)
      end
    end

    context 'when a target is provided that is not a file' do
      let(:target) { { name: 'environment.conf', file: false } }

      it 'skips the target' do
        expect(report).not_to receive(:add_event)
      end
    end

    context 'when a target is provided that is empty' do
      let(:target) { { name: 'environment.conf', content: '' } }

      it 'adds a passing event to the report' do
        expect(report).to receive(:add_event).with({
                                                     file: target[:name],
                                                     source: validator.name,
                                                     state: :passed,
                                                     severity: 'ok',
                                                   })
        expect(return_value).to eq(0)
      end
    end

    context 'when a target is provided that has all allowed settings and is valid' do
      let(:target) do
        {
          name: 'environment.conf',
          content: <<-EOT,
                   modulepath=foo
                   manifest=foo
                   config_version=foo
                   environment_timeout=0
          EOT
        }
      end

      it 'adds a passing event to the report' do
        expect(report).to receive(:add_event).with({
                                                     file: target[:name],
                                                     source: validator.name,
                                                     state: :passed,
                                                     severity: 'ok',
                                                   })
        expect(return_value).to eq(0)
      end
    end

    context 'when a target is provided that has invalid settings and sections' do
      let(:target) do
        {
          name: 'environment.conf',
          content: <<-EOT,
                   modulepath=foo
                   manifest=foo
                   config_version=foo
                   environment_timeout=foo
                   invalid=true

                   [invalid_section]
                   invalid=true
          EOT
        }
      end

      it 'does not add a passing event to the report' do
        expect(report).not_to receive(:add_event).with(
          state: :passed
        )
        expect(return_value).to eq(1)
      end

      it 'adds a invalid setting failures event to the report' do
        allow(report).to receive(:add_event).and_call_original
        expect(report).to receive(:add_event).with({
                                                     file: target[:name],
                                                     source: validator.name,
                                                     state: :failure,
                                                     severity: 'error',
                                                     message: a_string_matching(/Invalid setting 'invalid'/),
                                                   })
        expect(return_value).to eq(1)
      end

      it 'adds a invalid section failures event to the report' do
        allow(report).to receive(:add_event).and_call_original
        expect(report).to receive(:add_event).with({
                                                     file: target[:name],
                                                     source: validator.name,
                                                     state: :failure,
                                                     severity: 'error',
                                                     message: a_string_matching(/Invalid section 'invalid_section'/),
                                                   })
        expect(return_value).to eq(1)
      end

      it 'adds a invalid environment_timeout failures event to the report' do
        allow(report).to receive(:add_event).and_call_original
        expect(report).to receive(:add_event).with({
                                                     file: target[:name],
                                                     source: validator.name,
                                                     state: :failure,
                                                     severity: 'error',
                                                     message: a_string_matching(/environment_timeout is set to 'foo' but should be/),
                                                   })
        expect(return_value).to eq(1)
      end
    end
  end
end
