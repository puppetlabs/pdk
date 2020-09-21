module PDK
  module Module
    autoload :Build, 'pdk/module/build'
    autoload :Convert, 'pdk/module/convert'
    autoload :Metadata, 'pdk/module/metadata'
    autoload :Release, 'pdk/module/release'
    autoload :UpdateManager, 'pdk/module/update_manager'
    autoload :Update, 'pdk/module/update'

    DEFAULT_IGNORED = [
      '/pkg/',
      '~*',
      '/coverage',
      '/checksums.json',
      '/REVISION',
      '/spec/fixtures/modules/',
      '/vendor/',
      '.DS_Store',
    ].freeze

    def default_ignored_pathspec(ignore_dotfiles = true)
      require 'pathspec'

      PathSpec.new(DEFAULT_IGNORED).tap do |ps|
        ps.add('.*') if ignore_dotfiles
      end
    end
    module_function :default_ignored_pathspec
  end
end
