# == Class: java
#
# This class installs and manages jdk
#
# === Parameters
#
# None
#
# === Variables
#
# Inherited from java::params class
#
# === Requires
#
# java::params
#
# === Sample Usage
#
# include java
#
# === Authors
#
# Ashrith <ashrith@me.com>

class java {

  require java::params

  file {"$java::params::java_base":
    ensure  => "directory",
    owner   => "root",
    group   => "root",
    alias   => "java-base"
  }

  file { "${java::params::java_base}/jdk${java::params::java_version}.tar.gz":
    mode    => 0644,
    owner   => root,
    group   => root,
    source  => "puppet:///modules/java/jdk${java::params::java_version}.tar.gz",
    alias   => "java-source-tgz",
    before  => Exec["untar-java"],
    require => File["java-base"]
  }

  exec { "untar jdk${java::params::java_version}.tar.gz":
    command     => "/bin/tar -zxf jdk${java::params::java_version}.tar.gz",
    cwd         => "${java::params::java_base}",
    creates     => "${java::params::java_base}/jdk${java::params::java_version}",
    alias       => "untar-java",
    refreshonly => true,
    subscribe   => File["java-source-tgz"],
    before      => File["java-app-dir"]
  }

  file { "${java::params::java_base}/jdk${java::params::java_version}":
    ensure  => "directory",
    mode    => 0644,
    owner   => root,
    group   => root,
    alias   => "java-app-dir"
  }

  file { "/etc/profile.d/java_home.sh":
    ensure    =>	present,
    content	  =>	template("java/java_home.sh.erb"),
    mode      => 0755,
    owner	    => root,
    group     => root,
    require	  =>	File["java-app-dir"],
  }
  
  #FIX: This causes java to source every time
  exec { "source-java":
    command	  => "/etc/profile.d/java_home.sh | sh",
    user      => 'root',
    group     => 'root',
    logoutput => 'true',
    onlyif    => '/usr/bin/test -z $JAVA_HOME',
    require	  =>	File ["/etc/profile.d/java_home.sh"],
  }
}
