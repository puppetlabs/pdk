require 'cri'

module Pick
  module CLI
    class Generate
      def self.command
        @generate ||= Cri::Command.define do
          name 'generate'
          usage 'generate [template] [name] [source]'
          summary 'generates a `template thing named `name`'
          description 'Creates all of the files necessary to create a new <template>...'

          option nil, :name, 'The name of the module', argument: :required
          option nil, :template, 'The template to use', argument: :optional
          option nil, :source, 'The source repository to load templates from.', argument: :optional

          run do |opts, args, cmd|
            template = opts.fetch(:template, 'example')
            source = opts.fetch(:source, 'git@github.com:puppetlabs/modulesync_configs.git')
            name = opts.fetch(:name)
            puts "Generating a #{template} named '#{name}' from source #{source}..."
            Pick::Generate.generate(template, name, opts)
            puts "Generation done. Enjoy your new #{template}!"
          end
        end
      end
    end
  end
end
