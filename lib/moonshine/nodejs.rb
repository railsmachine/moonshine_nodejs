#
#
# Moonshine will autoload plugins, just call the recipe(s) you need in your
# manifests:
#
#    recipe :nodejs
#

module Moonshine
  module Nodejs
    def legacy_nodejs
      file '/etc/apt/sources.list.d/nodejs.list',
        :ensure => :present,
        :mode => '644',
        :content => template(File.join(File.dirname(__FILE__), '..', '..', 'templates', 'nodejs.list.erb'), binding)

      exec 'ppa:chris-lea/node.js apt-key',
        :command => 'apt-key adv --keyserver keyserver.ubuntu.com --recv C7917B12',
        :unless => 'apt-key list | grep C7917B12',
        :logoutput => :on_failure

      exec 'apt-get update',
        :command => 'apt-get update',
        :require => [
          file('/etc/apt/sources.list.d/nodejs.list'),
          exec('ppa:chris-lea/node.js apt-key')
        ],
        :logoutput => :on_failure

      package :nodejs, :ensure => :installed
    end

    def nodejs(options = {})
      version = options.fetch(:version, 5)
      version = "node_#{version}.x"

      exec 'NodeSource signing key',
        command: 'curl --silent https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -',
        unless: 'false',
        logoutput: :on_failure

      file '/etc/apt/sources.list.d/nodejs.list',
        ensure: :absent

      file '/etc/apt/sources.list.d/nodesource.list',
        ensure: :present,
        mode: '644',
        content: "deb https://deb.nodesource.com/#{version} #{Facter.value(:lsbdistcodename)} main",
        require: [exec('NodeSource signing key'), file('/etc/apt/sources.list.d/nodejs.list')]

      exec 'node.js apt-get update',
        require: file('/etc/apt/sources.list.d/nodesource.list'),
        refreshonly: true

      package :nodejs, ensure: :installed, require: exec('node.js apt-get update')
    end
  end
end
