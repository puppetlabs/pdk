RSpec::Matchers.define :have_no_output do
  match do |text|
    values_match?(/\A\Z/, text)
  end

  diffable
end
