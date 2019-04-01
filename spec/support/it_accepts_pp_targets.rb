RSpec.shared_examples_for 'it accepts .pp targets' do
  describe '.pattern' do
    it 'matches manifest files' do
      expect(described_class.pattern).to include('**/*.pp')
    end
  end
end
