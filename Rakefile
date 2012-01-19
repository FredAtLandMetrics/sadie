require "bundler/gem_tasks"

require 'rake'
require 'rake/rdoctask'

task    :default    =>  [:test]

task :test do
    ruby "test/tc_sadie_toplevel.rb"
    ruby "test/tc_sadie_twodeep.rb"
end

# task :rdoc do
#     
# end
Rake::RDocTask.new do |rdoc|
    rdoc.title = 'Sadie'
    rdoc.rdoc_files.include('lib/**/*.rb')
    rdoc.rdoc_files.include('README')
    rdoc.main = 'README'
    rdoc.rdoc_dir = 'rdoc'
end
