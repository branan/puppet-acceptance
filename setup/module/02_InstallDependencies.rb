require 'yaml'

step "Parse the dependencies yaml"

begin
  modules = YAML.load_file("#{options[:modroot]}/.fixtures.yml")["fixtures"]
rescue
  modules = {"repositories" => {}}
end

masters = hosts.select { |host| host['roles'].include? 'master' }
modules["repositories"].each do |name, repo|
  moddir = "/etc/puppet/modules"
  target = "#{moddir}/#{name}"

  step "Clone #{repo} if needed"
  on masters, "test -d #{moddir} || mkdir -p #{moddir}"
  on masters, "test -d #{target} || git clone #{repo} #{target}"

  step "Update #{repo} to latest master"
  commands = ["cd #{target}",
              "remote rm origin",
              "remote add origin #{repo}",
              "fetch origin",
              "checkout -f origin/master",
              "reset --hard refs/remotes/origin/master",
              "clean -fdx",
             ]

  on masters, commands.join(" && git ")
end
