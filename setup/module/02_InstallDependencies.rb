require 'yaml'

step "Parse the dependencies yaml"

begin
  modules = Yaml.load_file("#{options[:modroot]}/acceptance/dependencies.yml")
rescue
  modules = {"modules" => []}
end

modules["modules"].each do |pair|
  pair.each do |repo, name|
    moddir = "/etc/puppet/modules"
    target = "#{moddir}/#{name}"

    step "Clone #{repo} if needed"
    on masters, "test -d #{moddir} || mkdir -p #{moddir}"
    on masters, "test -d #{target} || git clone #{repo} /etc/puppet/modules/#{name}"

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
end
