#-----------------------------------------------------------------------------#
# Class: cron
#
# This module manages cron
#
# Parameters: none
#
# Actions:
#
#
#
# Sample Usage:
#
# cron::ensure_state: 'running' => ensure the service started, this is
# the default value (can be set to 'stopped')
# cron::enable: 'false' => set the service to start during the server boot,
# default value = 'true'.
#----------------------------------------------------------------------------#

class cron (
  #Default values
  $enable_cron      = true,
  $package_ensure   = 'present',
  $ensure_state     = 'running',
  $crontab_path     = '/etc/crontab',
  $cron_allow       = 'absent',
  $cron_deny        = 'absent',
  $cron_allow_path  = '/etc/cron.allow',
  $cron_deny_path   = '/etc/cron.deny',
  $cron_files       = undef,
  #$var_spool_cron   = undef,
  $cron_allow_users = undef,
  $cron_deny_users  = undef,
  $crontab_vars     = '',
  $crontab_tasks    = '',

) {

  # Check the client os to define the package name and service name

  case $::osfamily {
    'Ubuntu', 'Suse': {
      $package_name = 'cron'
      $service_name = 'cron'
    }
    'RedHat', 'Centos': {
      $package_name = 'crontabs'
      $service_name = 'crond'
    }
    default: {
      fail("cron supports RedHat, CentOS, Suse and Ubuntu. Detected osfamily is <${::osfamily}>.")
    }
  }

# validation
  validate_re($ensure_state, '^(running)|(stopped)$', "cron::ensure_state is ${ensure_state} and must be running or stopped")
  validate_re($package_ensure, '^(present)|(absent)$', "cron::package_ensure is ${package_ensure} and must be absent or present")
  validate_re($cron_allow, '^(present)|(absent)$', "cron::cron_allow is ${cron_allow} and must be absent or present")
  validate_re($cron_deny, '^(present)|(absent)$', "cron::cron_deny is ${cron_deny} and must be absent or present")

  case type($enable_cron) {
    'string': {
      validate_re($enable_cron, '^(true|false)$', "cron::enable_cron may be either 'true' or 'false' and is set to <${enable_cron}>")
      $enable_cron_real = str2bool($enable_cron)
    }
    'boolean': {
      $enable_cron_real = $enable_cron
    }
    default: {
      fail('cron::enable_cron type must be true or false.')
    }
  }
  if $cron_allow_users != undef {
    validate_array($cron_allow_users)
    $cron_allow_real='present'
  } else {
    $cron_allow_real=$cron_allow
  }
  if $cron_deny_users != undef {
    validate_array($cron_deny_users)
    $cron_deny_real='present'
  } else {
    $cron_deny_real=$cron_deny
  }
  if $cron_files != undef {
    create_resources(cron::fragment,$cron_files)
  }
  if ($crontab_tasks != '') {
    validate_hash($crontab_tasks)
  }
  if ($crontab_vars != '') {
    validate_hash($crontab_vars)
  }
# End of validation

  file {'cron_allow':
    ensure  => $cron_allow_real,
    path    => $cron_allow_path,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('cron/cron_allow.erb'),
    require => Package[$package_name],
  }

  file {'cron_deny':
    ensure  => $cron_deny_real,
    path    => $cron_deny_path,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('cron/cron_deny.erb'),
    require => Package[$package_name],
  }

  package {'cron':
    ensure => $package_ensure,
    name   => $package_name,
  }

  file {'crontab':
    ensure  => present,
    path    => $crontab_path,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('cron/crontab.erb'),
    require => Package[$package_name],
  }

  service {'cron':
    ensure    => $ensure_state,
    enable    => $enable_cron_real,
    name      => $service_name,
    require   => File['crontab'],
    subscribe => File['crontab'],
  }

}

