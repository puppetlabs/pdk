require 'spec_helper'
require 'pdk/validate/puppet/puppet_plan_syntax_validator'

describe PDK::Validate::Puppet::PuppetPlanSyntaxValidator do
  subject(:validator) { described_class.new(validator_context, options) }

  let(:validator_context) { nil }
  let(:options) { {} }
  let(:tmpdir) { File.join('/', 'tmp', 'puppet-plan-parser-validate') }

  before do
    allow(Dir).to receive(:mktmpdir).with('puppet-plan-parser-validate').and_return(tmpdir)
    allow(PDK::Util::Filesystem).to receive(:remove_entry_secure).with(tmpdir)
  end

  it 'defines the ExternalCommandValidator attributes' do
    expect(validator).to have_attributes(
      name: 'puppet-plan-syntax',
      cmd: 'puppet',
    )
    expect(validator.spinner_text_for_targets(nil)).to match(%r{puppet plan syntax}i)
  end

  describe '.pattern' do
    it 'only contextually matches puppet plans' do
      expect(validator).to receive(:contextual_pattern).with('plans/**/*.pp') # rubocop:disable RSpec/SubjectStub This is fine
      validator.pattern
    end
  end

  describe '.pattern_ignore' do
    it 'ignores nothing' do
      expect(validator).not_to receive(:contextual_pattern) # rubocop:disable RSpec/SubjectStub This is fine
      validator.pattern_ignore
    end
  end

  describe '.invoke' do
    context 'when the validator runs correctly' do
      before do
        allow(validator).to receive(:parse_targets).and_return([[], [], []]) # rubocop:disable RSpec/SubjectStub
      end

      it 'cleans up the temp dir after invoking' do
        expect(validator).to receive(:remove_validate_tmpdir) # rubocop:disable RSpec/SubjectStub
        validator.invoke(PDK::Report.new)
      end
    end

    context 'when the validator raises an exception' do
      before do
        allow(validator).to receive(:parse_targets).and_raise(PDK::CLI::FatalError) # rubocop:disable RSpec/SubjectStub
      end

      it 'cleans up the temp dir after invoking' do
        expect(validator).to receive(:remove_validate_tmpdir) # rubocop:disable RSpec/SubjectStub
        expect {
          validator.invoke(PDK::Report.new)
        }.to raise_error(PDK::CLI::FatalError)
      end
    end
  end

  describe '.remove_validate_tmpdir' do
    after do
      validator.remove_validate_tmpdir
    end

    context 'when a temp dir has been created' do
      before do
        validator.validate_tmpdir
      end

      context 'and the path is a directory' do
        before do
          allow(PDK::Util::Filesystem).to receive(:directory?).with(tmpdir).and_return(true)
        end

        it 'removes the directory' do
          expect(PDK::Util::Filesystem).to receive(:remove_entry_secure).with(tmpdir)
        end
      end

      context 'but the path is not a directory' do
        before do
          allow(PDK::Util::Filesystem).to receive(:directory?).with(tmpdir).and_return(false)
        end

        it 'does not attempt to remove the directory' do
          expect(PDK::Util::Filesystem).not_to receive(:remove_entry_secure)
        end
      end
    end
  end

  describe '.parse_options' do
    subject(:command_args) { validator.parse_options(targets) }

    let(:targets) { ['target1', 'target2.pp'] }

    before do
      allow(Gem).to receive(:win_platform?).and_return(false)
    end

    it 'invokes `puppet parser validate --tasks`' do
      expect(command_args.first(3)).to eq(['parser', 'validate', '--tasks'])
    end
  end
end
