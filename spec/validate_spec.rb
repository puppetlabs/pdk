require 'spec_helper'

describe PDK::Validate do
  it 'includes each of the validation tools' do
    expect(subject.validators).to eq([PDK::Validate::Metadata,
                                      PDK::Validate::PuppetLint,
                                      PDK::Validate::PuppetParser,
                                      PDK::Validate::RubyLint])
  end
end
