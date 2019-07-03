task :command_spec do
  require 'pdk/cli'
  require 'json'

  base_command = PDK::CLI.instance_variable_get('@base_cmd')
  result = describe_command(base_command)
  puts JSON.pretty_generate(result)
end

def describe_command(cri_command)
  {
    'name'        => cri_command.name,
    'aliases'     => cri_command.aliases.to_a,
    'description' => cri_command.description,
    'hidden'      => cri_command.hidden,
    'summary'     => cri_command.summary,
    'usage'       => cri_command.summary,
    'options'     => cri_command.option_definitions.map { |r| describe_option(r) },
    'subcommands' => cri_command.subcommands.map { |r| describe_command(r) },
  }
end

def describe_option(cri_option)
  cri_option.reject { |k, _| k == :block }
end
