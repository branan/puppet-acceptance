require 'pathname'

# the spec fixtures will often have a recursive symlink. Unfortunately, our
# ssh library doesn't let us skip traversing symlinks. This awful mess
# exists so that we can get those symlinks out of the module.
fixtures = Pathname("#{options[:modroot]}/spec/fixtures")
tmpdir = false
if fixtures.exist?
  step "Move the fixtures directory to avoid a recursive tree"
  tmpdir = Dir.mktmpdir
  fixtures.rename("#{tmpdir.to_s}/fixtures")
end

step "Masters: install the module to be tested"
masters = hosts.select { |host| host['roles'].include? 'master' }
moddir = "/etc/puppet/modules/#{options[:modname]}"
# Check if the moddir exsits, and if so remove it. the ||true makes sure the
# test suite doesn't explode if the module isn't on the system
on masters, "test -d #{moddir} && rm -rf #{moddir} || true"
scp_to masters, options[:modroot], moddir

if tmpdir
  step "Restore the fixtures directory"
  Pathname("#{tmpdir}/fixtures").rename(fixtures.to_s)
  FileUtils.remove_entry_secure(tmpdir)
end
