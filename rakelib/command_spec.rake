task :command_spec do
  require 'json'

  puts JSON.pretty_generate(describe_base_command)
end

task :generate_powershell do
  root_dir = File.expand_path(File.join(__dir__, '..'))
  ext_dir = File.join(root_dir, 'ext')
  output_dir = File.join(root_dir, 'output', 'PowerShell')

  if Dir.exist?(output_dir)
    puts "Cleaning #{output_dir}"
    FileUtils.rm_rf(output_dir)
  end
  FileUtils.mkdir_p(output_dir)

  @pdk_pwsh_commands = cri_to_powershell_hash(describe_base_command)

  ['PuppetDevelopmentKit', 'PuppetDevelopmentKitBeta'].each do |dir|
    this_output = File.join(output_dir, dir)
    FileUtils.mkdir_p(this_output)
    Dir.glob(File.join(ext_dir, dir, '/*')).each do |file|
      if File.extname(file) == '.erb'
        dest_path = File.join(this_output, File.basename(file)[0..-5])
        puts "Generating #{dest_path} ..."
        # Create the ERB template object
        template = ERB.new(File.open(file, 'rb:utf-8') { |f| f.read }, trim_mode: '-')
        # Generating the content
        new_content = template.result
        File.open(dest_path, 'wb:utf-8') { |f| f.write(new_content) }
      else
        dest_path = File.join(this_output, File.basename(file))
        puts "Copying #{dest_path} ..."
        # Copy is binary so no need to worry about binmode or encodings
        FileUtils.copy(file, dest_path)
      end
    end
  end
end

def to_title_case(value)
  # A quick method to TitleCase a string
  value.gsub(/[a-zA-Z0-9]+/, &:capitalize).delete('-').delete('_')
end

def cri_to_powershell_hash(base_command)
  output = []
  # Mapping of PDK CRI command to PowerShell Verb
  pdk_to_powershell = {
    'convert' => 'ConvertTo',
    'new' => 'New',
    'test' => 'Test',
    'update' => 'Update',
    'validate' => 'Validate',
  }

  base_command['subcommands'].select { |item| pdk_to_powershell.key?(item['name']) }
                             .each do |cmd|
    pdk_verb = cmd['name']
    pwsh_verb = pdk_to_powershell[pdk_verb]

    has_subcommands = cmd['subcommands'].count.positive?
    sub_commands = has_subcommands ? cmd['subcommands'].reject { |item| item['name'] == 'help' } : [cmd]

    sub_commands.each do |sub_command|
      # Convert the PDK name into a PowerShell compatible Function name
      function_name = "#{pwsh_verb}-PDK"
      function_name += has_subcommands ? to_title_case(sub_command['name']) : 'Module'

      ps_command = {
        'description' => sub_command['summary'],
        'pdk_verb' => pdk_verb,
        'function_name' => function_name,
      }
      ps_command['pdk_subcommand'] = sub_command['name'] if has_subcommands

      # Extract all of the explicit CRI options into a format we can use in PowerShell
      options_hash = {}
      sub_command['options'].each do |option|
        obj = {
          'pdkname' => option[:long], # The PDK argument name
          'desc' => option[:desc], # A description of the parameter
          'type' => 'String', # The PowerShell Type of the parameter
          'reserved' => false, # Whether this is a reserved PowerShell name e.g. Verbose
          'position' => -1, # What position the parameter has. -1 means no position
        }
        obj['type'] = 'Switch' if option[:argument] == :forbidden
        if option[:long] == 'verbose'
          obj['type'] = 'Verbose'
          obj['reserved'] = true
        end
        options_hash[to_title_case(option[:long])] = obj
      end

      # Not all CRI options are explicit. Some are implicitly inside the usage text surrounded by angle brackets < >
      # Extract these from the usage text. Also these are positional
      position = 0
      sub_command['usage']&.match(/(?:<([^>]+)>)/) do |match|
        pdk_name = match.captures[0]
        pwsh_name = to_title_case(pdk_name)
        options_hash[pwsh_name] = {
          'desc' => "The specified #{pdk_name}", # A description of the parameter
          'type' => 'String', # The PowerShell Type of the parameter
          'reserved' => false, # Whether this is a reserved PowerShell name e.g. Verbose
          'position' => position, # What position the parameter has. -1 means no position
        }
        position += 1
      end

      ps_command['options'] = options_hash
      output << ps_command
    end
  end
  output
end

def describe_base_command
  require 'pdk/cli'

  base_command = PDK::CLI.instance_variable_get(:@base_cmd)
  describe_command(base_command)
end

def describe_command(cri_command)
  {
    'name' => cri_command.name,
    'aliases' => cri_command.aliases.to_a,
    'description' => cri_command.description,
    'hidden' => cri_command.hidden,
    'summary' => cri_command.summary,
    'usage' => cri_command.summary,
    'options' => cri_command.option_definitions.map { |r| describe_option(r) },
    'subcommands' => cri_command.subcommands.map { |r| describe_command(r) },
  }
end

def cri_option_is_a_hash?
  return @cri_option_is_a_hash unless @cri_option_is_a_hash.nil?

  @cri_option_is_a_hash = Gem::Version.new(Cri::VERSION) <= Gem::Version.new('2.11.0')
  @cri_option_is_a_hash
end

def describe_option(cri_option)
  (cri_option_is_a_hash? ? cri_option : cri_option.to_h).reject { |k, _| k == :block }
end
