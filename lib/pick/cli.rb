require 'pick'
require 'thor'

module Pick
  class CLI < Thor
    desc 'generate [template] [name]', 'generates a `template` thing named `name`.'
    method_option :source, default: 'git@github.com:puppetlabs/modulesync_configs.git', desc: 'The source repository to load templates from.'

    def generate(template='module', name = 'example')
      puts "Generating a #{template} named '#{name}' ..."
      Pick::Generate.generate(template, name, options)
      puts "Generation done. Enjoy your new #{template}!"
    end
  end
end
