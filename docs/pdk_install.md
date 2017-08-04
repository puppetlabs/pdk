
**Note: this page is a draft in progress and is neither technically reviewed nor edited. Do not rely on information in this draft.**

## Installing the Puppet Development Kit

Install the Puppet Development Kit (PDK) as your first step in creating and testing Puppet modules.

### Before you begin

PDK is a stand-alone development kit and does not require a pre-existing installation of Puppet. On Linux-based systems, you must enable the repository before you can download and install the package.

If you used an early release version of PDK, we recommend you uninstall it before installing PDK 1.0. Use your platform's package manager to uninstall any PDK versions earlier than 1.0, and then install the updated 1.0 package.

By default, PDK installs to:

* Linux and OS X systems: `/opt/puppetlabs/pdk/`
* Windows systems: `C:\Program Files\Puppet Labs\DevelopmentKit`


### Supported operating systems

| Operating system | Version(s) | Arch | PkgType |
| ---------------- | ---------- | ---- | ------- |
| Red Hat Enterprise Linux | 6, 7 | x86_64 | RPM |
| CentOS | 6, 7 | x86_64 | RPM |
| Oracle Linux | 6, 7 | x86_64 | RPM |
| Scientific Linux | 6, 7 | x86_64 | RPM |
| SUSE Linux Enterprise Server | 11, 12 | x86_64 | N/A |
| Ubuntu | 14.04. 16.04 | x86_64 | DEB |
| Windows (Consumer OS) | 7, 8.1, 10 | x86_64 | MSI |
| Windows Server (Server OS) | 2008r2, 2012, 2012r2, 2012r2 Core, and 2016 | x86_64 | MSI |
| Mac OS X | 10.11, 10.12 | x86_64 | N/A |



## Enable the PDK repository on Linux

Before you can download and install the PDK, you must enable the package repository to your respective Linux platform. 


### Enable PDK repo on Yum-based systems

Before you can install the PDK package, enable the PDK release repository on your Yum-based system.

1. Choose the package based on your operating system and version.

   Packages are located in the [`yum.puppet.com/pdk`](https://yum.puppet.com/pdk) repository and are named using the PDK package name and version, followed by the OS abbreviation and version.

   For instance, the PDK repository package for Red Hat Enterprise Linux 7 (RHEL 7) is `pdk-release-el7.rpm`.

2. Install with `rpm` as root with the `upgrade` (`-U`) flag, and optionally the `verbose` (`-v`), and `hash` (`-h`) flags.

   For example:

   `sudo rpm -Uvh https://yum.puppet.com/pdk/pdk-release-el7.rpm`

### Enable PDK repo on Apt-based systems

Before you can install the PDK package, enable the PDK release repository on your Apt-based system.

1. Choose the package based on your operating system and version.

   The packages are located in the [`apt.puppet.com/pdk`](https://apt.puppet.com/pdk) and are named using the PDK package name and version, followed by the OS abbreviation and version.

   For instance, the PDK repository package for on Debian 7 "Wheezy" is `pdk-release-wheezy.deb`. For Ubuntu releases, the code name is the adjective, not the animal.

2. Download the PDK package and install it as root using `dpkg` and the `install` flag (`-i`):

```
wget https://apt.puppetlabs.com/pdk-release-wheezy.deb
sudo dpkg -i pdk-release-wheezy.deb
```

3. Run `apt-get update` after installing the release package to update the `apt` package lists.

{:.task}
### Install PDK on Linux-based systems 

1. Install the `pdk` package using the command appropriate to your system:

   * Apt: `sudo apt-get install pdk`
   * Yum: `sudo yum install pdk`

2. Open a new terminal to re-source your shell profile and make PDK available to your PATH.

### Install PDK on OS X

1. Download the PDK package from [TODO link to the puppet-pdk package for OS X on the Puppet downloads site](downloads.puppetlabs.com).
1. Double click on the downloaded package to install.
1. Open a new terminal to re-source your shell profile and make PDK available to your PATH.

### Install PDK on Windows

1. Download the PDK package from [TODO link to the puppet-pdk MSI on the Puppet downloads site](downloads.puppetlabs.com).
1. Double click on the downloaded package to install.
2. Open a new terminal or Powershell window to re-source your profile and make PDK available to your PATH.
 

