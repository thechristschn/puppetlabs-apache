# @summary
#   A wrapper around the `apache::custom_config` defined type.
#  
# The `apache::vhost::custom` defined type is a thin wrapper around the `apache::custom_config` defined type, and simply overrides some of its default settings specific to the virtual host directory in Apache.
#
# @param content
#   Sets the configuration file's content.
#
# @param ensure
#   Specifies if the virtual host file is present or absent.
#
# @param vhost_symlink_ensure
#   Specifies if the symlink for the virtual host is present or absent. This only has an effect if
#   `apache::vhost_enable_dir` is set. If undefined, the value of `ensure` is used.
#
# @param priority
#   Sets the relative load order for Apache HTTPD VirtualHost configuration files.
#
# @param verify_config
#   Specifies whether to validate the configuration file before notifying the Apache service.
#
define apache::vhost::custom(
  $content,
  $ensure = 'present',
  $vhost_symlink_ensure = undef,
  $priority = '25',
  $verify_config = true,
) {
  include ::apache

  ## Apache include does not always work with spaces in the filename
  $filename = regsubst($name, ' ', '_', 'G')

  ::apache::custom_config { $filename:
    ensure        => $ensure,
    confdir       => $::apache::vhost_dir,
    content       => $content,
    priority      => $priority,
    verify_config => $verify_config,
  }

  # NOTE(pabelanger): This code is duplicated in ::apache::vhost and needs to
  # converted into something generic.
  if $::apache::vhost_enable_dir {
    if $vhost_symlink_ensure {
      $_vhost_symlink_ensure = $vhost_symlink_ensure
    } else {
      $_vhost_symlink_ensure = $ensure ? {
        present => link,
        default => $ensure,
      }
    file { "${priority}-${filename}.conf symlink":
      ensure  => $_vhost_symlink_ensure,
      path    => "${::apache::vhost_enable_dir}/${priority}-${filename}.conf",
      target  => "${::apache::vhost_dir}/${priority}-${filename}.conf",
      owner   => 'root',
      group   => $::apache::params::root_group,
      mode    => $::apache::file_mode,
      require => Apache::Custom_config[$filename],
      notify  => Class['apache::service'],
    }
  }
}
