require 'spec_helper'

describe Pick::Validate do
  it 'should include each of the validation tools' do
    expect(subject.validators).to eq([Pick::Validate::Metadata,
                                      Pick::Validate::PuppetLint,
                                      Pick::Validate::PuppetParser,
                                      Pick::Validate:: RubyLint])
  end
end
