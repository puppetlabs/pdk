RSpec::Matchers.define :have_no_output do
  match do |text|
    values_match?(%r{\A\Z}, text)
  end

  diffable
end
