# Similar to RSpec’s built-in #hash_including, but does not require the keys of
# `expected` to be present in `actual` -- what matters is that for all keys in
# `expected`, the value in `actual` and `expected` is the same.
#
#     hash = Hash.new { |hash, key| 9000 }
#     moo(hash)
#
# This passes:
#
#     expect(something)
#       .to receive(:moo)
#       .with(hash_with_defaults_including(stuff: 9000))
#
# This does not pass:
#
#     expect(something)
#       .to receive(:moo)
#       .with(hash_including(stuff: 9000))
RSpec::Matchers.define :hash_with_defaults_including do |expected|
  include RSpec::Matchers::Composable

  match do |actual|
    expected.keys.all? do |key|
      values_match?(expected[key], actual[key])
    end
  end

  description do
    "hash_with_defaults_including(#{expected.inspect})"
  end
end
