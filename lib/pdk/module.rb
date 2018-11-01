require 'pathspec'

module PDK
  module Module
    DEFAULT_IGNORED = [
      '/pkg/',
      '.*',
      '~*',
      '/coverage',
      '/checksums.json',
      '/REVISION',
      '/spec/fixtures/modules/',
      '/vendor/',
    ].freeze

    def default_ignored_pathspec
      @default_ignored_pathspec ||= PathSpec.new(DEFAULT_IGNORED)
    end
    module_function :default_ignored_pathspec
  end
end
