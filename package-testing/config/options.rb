{
  ssh: {
    # keys: ['~/.ssh/id_rsa-acceptance'],
    verify_host_key: :never,
  },
  preserve_hosts: 'onfail',
  provision: 'true',
}
