require 'spec_helper_acceptance'

describe 'pdk validate puppet', module_command: true do
  let(:junit_xsd) { File.join(RSpec.configuration.fixtures_path, 'JUnit.xsd') }
  let(:syntax_spinner_text) { %r{checking puppet manifest syntax}i }
  let(:lint_spinner_text) { %r{checking puppet manifest style}i }
  let(:empty_string) { %r{\A\Z} }

  init_pp = File.join('manifests', 'init.pp')
  example_pp = File.join('manifests', 'example.pp')

  context 'with no .pp files' do
    include_context 'in a new module', 'foo'

    describe command('pdk validate puppet') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.not_to match(syntax_spinner_text) }
      its(:stderr) { is_expected.not_to match(lint_spinner_text) }
      its(:stdout) { is_expected.to match(empty_string) }
    end

    describe command('pdk validate puppet --format junit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.not_to match(syntax_spinner_text) }
      its(:stderr) { is_expected.not_to match(lint_spinner_text) }

      its(:stdout) { is_expected.to pass_validation(junit_xsd) }
      its(:stdout) { is_expected.not_to have_xpath('/testsuites/testsuite[@name="puppet-syntax"]') }
      its(:stdout) { is_expected.not_to have_xpath('/testsuites/testsuite[@name="puppet-lint"]') }
    end
  end

  context 'with a parsable file and no style problems' do
    include_context 'in a new module', 'foo'

    before(:all) do
      File.open(init_pp, 'w') do |f|
        f.puts <<-EOS
# foo
class foo {
}
        EOS
      end
    end

    describe command('pdk validate puppet') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(syntax_spinner_text) }
      its(:stderr) { is_expected.to match(lint_spinner_text) }
      its(:stdout) { is_expected.to match(empty_string) }
    end

    describe command('pdk validate puppet --format junit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(syntax_spinner_text) }
      its(:stderr) { is_expected.to match(lint_spinner_text) }
      its(:stdout) { is_expected.to pass_validation(junit_xsd) }

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-syntax"]')
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-lint"]')
      end
    end
  end

  context 'with a parsable file that has syntax warnings' do
    include_context 'in a new module', 'foo'

    before(:all) do
      File.open(init_pp, 'w') do |f|
        f.puts <<-EOS
# foo
class foo {
  notify { 'this should raise a warning':
    message => "because of \\[\\] escape characters",
  }
}
        EOS
      end
    end

    describe command('pdk validate puppet') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(syntax_spinner_text) }
      its(:stderr) { is_expected.to match(lint_spinner_text) }

      its(:stdout) { is_expected.to match(%r{Warning: Unrecognized escape sequence \'\\\[\'}i) }
      its(:stdout) { is_expected.to match(%r{Warning: Unrecognized escape sequence \'\\\]\'}i) }
    end

    describe command('pdk validate puppet --format junit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(syntax_spinner_text) }
      its(:stderr) { is_expected.to match(lint_spinner_text) }
      its(:stdout) { is_expected.to pass_validation(junit_xsd) }

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-syntax"]').with_attributes(
          'failures' => satisfy { |v| v.to_i == 2 },
          'tests'    => satisfy { |v| v.to_i == 2 },
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-syntax"]/testcase').with_attributes(
          'classname' => 'puppet-syntax',
          'name'      => a_string_starting_with(init_pp),
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-syntax"]/testcase/failure').with_attributes(
          'type'    => a_string_matching(%r{warning}i),
          'message' => a_string_matching(%r{Unrecognized escape sequence \'\\\[\'}i),
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-syntax"]/testcase/failure').with_attributes(
          'type'    => a_string_matching(%r{warning}i),
          'message' => a_string_matching(%r{Unrecognized escape sequence \'\\\]\'}i),
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-lint"]').with_attributes(
          'failures' => satisfy { |v| v.to_i > 0 },
          'tests'    => satisfy { |v| v.to_i > 0 },
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-lint"]/testcase').with_attributes(
          'classname' => a_string_starting_with('puppet-lint'),
          'name'      => a_string_starting_with(init_pp),
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-lint"]/testcase/failure').with_attributes(
          'type'    => a_string_matching(%r{warning}i),
          'message' => a_string_matching(%r{double quoted string containing no variables}i),
        )
      end
    end
  end

  context 'with a parsable file and some style warnings' do
    include_context 'in a new module', 'foo'

    before(:all) do
      File.open(init_pp, 'w') do |f|
        f.puts 'class foo { }'
      end
    end

    describe command('pdk validate puppet') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to match(%r{^#{Regexp.escape(init_pp)}.+class not documented}i) }
      its(:stderr) { is_expected.to match(syntax_spinner_text) }
      its(:stderr) { is_expected.to match(lint_spinner_text) }
    end

    describe command('pdk validate puppet --format junit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(syntax_spinner_text) }
      its(:stderr) { is_expected.to match(lint_spinner_text) }
      its(:stdout) { is_expected.to pass_validation(junit_xsd) }

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-syntax"]').with_attributes(
          'failures' => '0',
          'tests'    => '1',
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-syntax"]/testcase').with_attributes(
          'classname' => 'puppet-syntax',
          'name'      => init_pp,
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-lint"]').with_attributes(
          'failures' => '1',
          'tests'    => '1',
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-lint"]/testcase').with_attributes(
          'classname' => 'puppet-lint.documentation',
          'name'      => a_string_starting_with(init_pp),
        )
      end
    end
  end

  context 'with a syntax failure' do
    include_context 'in a new module', 'foo'

    init_pp = File.join('manifests', 'init.pp')

    before(:all) do
      File.open(init_pp, 'w') do |f|
        f.puts <<-EOS
# foo
class foo {
  Fails here because of gibberish
}
        EOS
      end
    end

    describe command('pdk validate puppet') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stderr) { is_expected.to match(syntax_spinner_text) }
      its(:stderr) { is_expected.not_to match(lint_spinner_text) }

      its(:stdout) { is_expected.to match(%r{Error: This Name has no effect}i) }
      its(:stdout) { is_expected.to match(%r{Error: This Type-Name has no effect}i) }
      its(:stdout) { is_expected.to match(%r{Error: Language validation logged 2 errors. Giving up}i) }
    end

    describe command('pdk validate puppet --format junit') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stderr) { is_expected.to match(syntax_spinner_text) }
      its(:stderr) { is_expected.not_to match(lint_spinner_text) }
      its(:stdout) { is_expected.to pass_validation(junit_xsd) }

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-syntax"]').with_attributes(
          'failures' => satisfy { |v| v.to_i == 3 },
          'tests'    => satisfy { |v| v.to_i == 3 },
        )

        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-syntax"]/testcase').with_attributes(
          'classname' => 'puppet-syntax',
          'name'      => a_string_starting_with(init_pp),
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-syntax"]/testcase/failure').with_attributes(
          'type'    => 'Error',
          'message' => a_string_matching(%r{This Name has no effect. A Host Class Definition can not end with a value-producing expression without other effect}i),
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-syntax"]/testcase/failure').with_attributes(
          'type'    => 'Error',
          'message' => a_string_matching(%r{This Type-Name has no effect. A value was produced and then forgotten}i),
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-syntax"]/testcase/failure').with_attributes(
          'type'    => 'Error',
          'message' => a_string_matching(%r{Language validation logged 2 errors. Giving up}i),
        )
      end
    end
  end

  context 'with a parsable file and some style errors' do
    include_context 'in a new module', 'foo'

    before(:all) do
      File.open(example_pp, 'w') do |f|
        f.puts '# some documentation'
        f.puts 'class foo::bar { }'
      end
    end

    describe command('pdk validate puppet') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stdout) { is_expected.to match(%r{#{Regexp.escape(example_pp)}.+autoload module layout}i) }
      its(:stderr) { is_expected.to match(syntax_spinner_text) }
      its(:stderr) { is_expected.to match(lint_spinner_text) }
    end

    describe command('pdk validate puppet --format junit') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stderr) { is_expected.to match(lint_spinner_text) }
      its(:stdout) { is_expected.to pass_validation(junit_xsd) }

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-lint"]').with_attributes(
          'failures' => '1',
          'tests'    => '1',
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-lint"]/testcase').with_attributes(
          'classname' => 'puppet-lint.autoloader_layout',
          'name'      => a_string_starting_with(example_pp),
        )
      end
    end

    context 'when validating specific files' do
      clean_pp = File.join('manifests', 'clean.pp')

      before(:all) do
        File.open(clean_pp, 'w') do |f|
          f.puts '# some documentation'
          f.puts 'class foo::clean { }'
        end
      end

      describe command("pdk validate puppet #{clean_pp}") do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(empty_string) }
        its(:stderr) { is_expected.to match(syntax_spinner_text) }
        its(:stderr) { is_expected.to match(lint_spinner_text) }
      end

      describe command("pdk validate puppet --format junit #{clean_pp}") do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(syntax_spinner_text) }
        its(:stderr) { is_expected.to match(lint_spinner_text) }
        its(:stdout) { is_expected.to pass_validation(junit_xsd) }

        its(:stdout) do
          is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-syntax"]').with_attributes(
            'failures' => '0',
            'tests'    => '1',
          )
        end

        its(:stdout) do
          is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-syntax"]/testcase').with_attributes(
            'classname' => 'puppet-syntax',
            'name'      => a_string_starting_with(clean_pp),
          )
        end

        its(:stdout) do
          is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-lint"]').with_attributes(
            'failures' => '0',
            'tests'    => '1',
          )
        end

        its(:stdout) do
          is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-lint"]/testcase').with_attributes(
            'classname' => 'puppet-lint',
            'name'      => a_string_starting_with(clean_pp),
          )
        end
      end
    end

    context 'when validating specific directories' do
      another_problem_pp = File.join('manifests', 'bar', 'baz.pp')
      another_problem_dir = File.dirname(another_problem_pp)

      before(:all) do
        FileUtils.mkdir_p(another_problem_dir)
        File.open(another_problem_pp, 'w') do |f|
          f.puts 'class foo::bar::whoops { }'
        end
      end

      describe command("pdk validate puppet #{another_problem_dir}") do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stderr) { is_expected.to match(syntax_spinner_text) }
        its(:stderr) { is_expected.to match(lint_spinner_text) }
        its(:stdout) { is_expected.to match(%r{^#{Regexp.escape(another_problem_pp)}}) }
        its(:stdout) { is_expected.not_to match(%r{^#{Regexp.escape(example_pp)}}) }
      end

      describe command("pdk validate puppet --format junit #{another_problem_dir}") do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stderr) { is_expected.to match(syntax_spinner_text) }
        its(:stderr) { is_expected.to match(lint_spinner_text) }
        its(:stdout) { is_expected.to pass_validation(junit_xsd) }

        its(:stdout) do
          is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-lint"]').with_attributes(
            'failures' => '2',
            'tests'    => '2',
          )
        end

        its(:stdout) do
          is_expected.to have_xpath('/testsuites/testsuite[@name="puppet-lint"]/testcase').with_attributes(
            'classname' => a_string_starting_with('puppet-lint'),
            'name'      => a_string_starting_with(another_problem_pp),
          )
        end

        its(:stdout) do
          is_expected.not_to have_xpath('/testsuites/testsuite[@name="puppet-lint"]/testcase').with_attributes(
            'classname' => a_string_starting_with('puppet-lint'),
            'name'      => a_string_starting_with(example_pp),
          )
        end
      end
    end
  end
end
