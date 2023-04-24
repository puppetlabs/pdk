RSpec.shared_examples_for 'only valid in specified PDK contexts' do |*context_class|
  describe '.valid_in_context?' do
    [
      PDK::Context::None.new(nil),
      PDK::Context::Module.new(nil, nil),
      PDK::Context::ControlRepo.new(nil, nil)
    ].each do |pdk_context|
      context "in #{pdk_context.display_name}" do
        subject { described_class.new(pdk_context, {}).valid_in_context? }

        if context_class.include?(pdk_context.class)
          it { is_expected.to be(true) }
        else
          it { is_expected.to be(false) }
        end
      end
    end
  end
end
