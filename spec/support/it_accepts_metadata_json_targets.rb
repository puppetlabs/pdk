RSpec.shared_examples_for 'it accepts metadata.json targets' do
  describe '.pattern' do
    it 'matches metadata.json in the root' do
      expect(described_class.pattern).to include('metadata.json')
    end
  end
end
