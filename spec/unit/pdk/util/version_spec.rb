require 'spec_helper'

describe PDK::Util::Version do
  context 'Getting the version_string' do
    subject(:version_string) { described_class.version_string }

    it { is_expected.not_to be_nil }
  end
end
