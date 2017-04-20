require 'gettext-setup'

GettextSetup.initialize(File.absolute_path('../../locales', File.dirname(__FILE__)))
GettextSetup.negotiate_locale!(GettextSetup.candidate_locales)
