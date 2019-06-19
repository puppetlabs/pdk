RSpec.shared_examples_for 'it accepts .epp targets' do
  describe '.pattern' do
    it 'matches EPP files' do
      expect(described_class.pattern).to include('**/*.epp')
    end
  end
end
