require 'pdk'

module PDK
  module CLI
    module Util
      module UpdateManagerPrinter
        # Prints the summary for a PDK::Module::UpdateManager Object
        # @param update_manager [PDK::Module::UpdateManager] The object to print a summary of
        # @param options [Hash{Object => Object}] A list of options when printing
        # @option options [Boolean] :tense Whether to use future (:future) or past (:past) tense when printing the summary ("Files to be added" versus "Files added"). Default is :future
        #
        # @return [void]
        def self.print_summary(update_manager, options = {})
          require 'pdk/report'

          options = {
            tense: :future,
          }.merge(options)

          footer = false

          summary(update_manager).each do |category, files|
            next if files.empty?

            PDK::Report.default_target.puts('')
            PDK::Report.default_target.puts(generate_banner("Files #{(options[:tense] == :future) ? 'to be ' : ''}#{category}", 40))
            PDK::Report.default_target.puts(files.map(&:to_s).join("\n"))
            footer = true
          end

          if footer # rubocop:disable Style/GuardClause No.
            PDK::Report.default_target.puts('')
            PDK::Report.default_target.puts(generate_banner('', 40))
          end
        end

        #:nocov: Tested as part of the public methods
        # Returns a hash, summarizing the contents of the Update Manager object
        # @param update_manager [PDK::Module::UpdateManager] The object to create a summary of
        #
        # @return [Hash{Symbol => Array[String]}] A hash of each category and the file paths in each category
        def self.summary(update_manager)
          summary = {}
          update_manager.changes.each do |category, update_category|
            if update_category.respond_to?(:keys)
              updated_files = update_category.keys
            else
              begin
                updated_files = update_category.map { |file| file[:path] }
              rescue TypeError
                updated_files = update_category.to_a
              end
            end

            summary[category] = updated_files
          end

          summary
        end
        private_class_method :summary

        # Creates a line of text, with `text` centered in the middle
        # @param text [String] The text to put in the middle of the banner
        # @param width [Integer] The width of the banner in characters. Default is 80
        # @return [String] The generated banner
        def self.generate_banner(text, width = 80)
          padding = width - text.length
          banner = ''
          padding_char = '-'

          (padding / 2.0).ceil.times { banner << padding_char }
          banner << text
          (padding / 2.0).floor.times { banner << padding_char }

          banner
        end
        private_class_method :generate_banner
        #:nocov:
      end
    end
  end
end
