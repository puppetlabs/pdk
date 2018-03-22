# frozen_string_literal: true

{
  helper: 'lib/helper.rb',
  pre_suite: [
    'pre/000_install_package.rb',
  ],
  ssh: {
    keys: ['~/.ssh/id_rsa-acceptance'],
  },
}
