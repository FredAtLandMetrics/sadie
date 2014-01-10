require 'rdoc/task'

Rake::RDocTask.new do |rdoc|
    rdoc.title = 'Sadie'
    rdoc.rdoc_files.include('lib/**/*.rb')
    rdoc.rdoc_files.include('README','TODO','CHANGELOG')
    rdoc.main = 'README'
    rdoc.rdoc_dir = 'rdoc'
end
