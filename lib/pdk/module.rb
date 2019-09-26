module PDK
  module Module
    DEFAULT_IGNORED = [
      '/pkg/',
      '~*',
      '/coverage',
      '/checksums.json',
      '/REVISION',
      '/spec/fixtures/modules/',
      '/vendor/',
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
