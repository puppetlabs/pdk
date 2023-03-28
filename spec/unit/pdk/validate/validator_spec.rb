require 'spec_helper'
require 'pdk/validate/validator'

describe PDK::Validate::Validator do
  subject(:validator) { described_class.new(validator_context, validator_options) }

  let(:validator_context) { nil }
  let(:validator_options) { {} }
  let(:mock_spinner) do
    require 'pdk/cli/util/spinner'

    instance_double(
      TTY::Spinner,
      auto_spin: nil,
      success: nil,
      error: nil,
    )
  end

  context 'when given options at object creation' do
    let(:validator_options) { { 'abc' => :foo } }

    it 'remembers the options' do
      expect(validator.context).to be_a(PDK::Context::None)
    end

    it 'defaults to None context' do
      expect(validator.options).to eq(validator_options)
    end

    context 'with a real context' do
      let(:validator_context) { PDK::Context::Module.new(nil, nil) }

      it 'remembers the context' do
        expect(validator.context).to be(validator_context)
      end
    end
  end

  it 'has a valid_in_context? as a boolean' do
    expect(validator.valid_in_context?).to be(true).or be(false)
  end

  it 'has a spinner_text of nil' do
    expect(validator.spinner_text).to be_nil
  end

  it 'has a spinners_enabled? as a boolean' do
    expect(validator.spinners_enabled?).to be(true).or be(false)
  end

  it 'has a spinner of nil' do
    expect(validator.spinner).to be_nil
  end

  it 'has a name of nil' do
    expect(validator.name).to be_nil
  end

  describe '.start_spinner' do
    context 'when the spinner is nil' do
      it 'does not error' do
        expect { validator.start_spinner }.not_to raise_error
      end
    end

    context 'with a TTY::Spinner instance' do
      before(:each) do
        allow(validator).to receive(:spinner).and_return(mock_spinner) # rubocop:disable RSpec/SubjectStub This is fine
      end

      it 'invokes auto_spin' do
        expect(mock_spinner).to receive(:auto_spin)
        validator.start_spinner
      end
    end
  end

  describe '.stop_spinner' do
    context 'when the spinner is nil' do
      it 'does not error' do
        expect { validator.stop_spinner(false) }.not_to raise_error
      end
    end

    context 'with a TTY::Spinner instance' do
      before(:each) do
        allow(validator).to receive(:spinner).and_return(mock_spinner) # rubocop:disable RSpec/SubjectStub This is fine
      end

      it 'invokes succes when passed true' do
        expect(mock_spinner).to receive(:success)
        validator.stop_spinner(true)
      end

      it 'invokes error when passed false' do
        expect(mock_spinner).to receive(:error)
        validator.stop_spinner(false)
      end
    end
  end

  describe '.prepare_invoke!' do
    it 'indicates the validator is prepared' do
      # This test is a little fragile as it's using a private
      # instance variable
      expect(validator.prepared).to be(false)
      validator.prepare_invoke!
      expect(validator.prepared).to be(true)
    end
  end

  describe '.invoke' do
    let(:report) { PDK::Report.new }
    let(:validator_name) { 'mock-validator' }

    before(:each) do
      allow(validator).to receive(:name).and_return(validator_name) # rubocop:disable RSpec/SubjectStub This is fine
    end

    it 'returns an exitcode of zero' do
      expect(validator.invoke(report)).to eq(0)
    end

    it 'does not add events to the report' do
      expect(report.events.count).to eq(0)
      validator.invoke(report)
      expect(report.events.count).to eq(0)
    end
  end
end
