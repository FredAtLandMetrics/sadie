require "bundler/gem_tasks"

require 'rake'
require 'rdoc/task'

task    :default    =>  [:test]

# run sadie tests
task :test do
    ruby "test/tc_sadie_toplevel.rb"
    ruby "test/tc_sadie_twodeep.rb"
end

namespace :spec do
  
  desc "test sadie server library"
  task :sadie_server_lib do
    system "rspec spec/sadie_server_lib.rb"
  end
  
  namespace :storage_mechanism do
    desc "test the memory based storage mechanism"
    task :memory do
      system "rspec spec/storage_mechanisms/memory.rb"
    end
  end
  
  desc "test primer"
  task :primer do
    system "rspec spec/primer.rb"
  end
  
  desc "test storage manager"
  task :storage_manager do
    system "rspec spec/storage_manager.rb"
  end
  
  desc "test session"
  task :session do
    system "rspec spec/sadie_session.rb"
  end
end

# increment version
task :deploy => 'inc_version' do
    version = current_sadie_version
    sh "git push"
    sh "gem build sadie.gemspec"
    sh "gem push sadie-#{version}.gem"
end

# increment version
task :inc_version do
    version = current_sadie_version
    if (matches = version.match(/^(\d+\.\d+\.)(\d+)$/))
        pre = matches[1]
        post = Integer(matches[2]) + 1
        version = "#{pre}#{post}"
    end
    fh = File.open("lib/sadie/version.rb","w")
    fh.puts "class Sadie"
    fh.puts '  VERSION = "' + version + '"'
    fh.puts "end"
    fh.close
    puts "incremented sadie version to #{version}"
end

Rake::RDocTask.new do |rdoc|
    rdoc.title = 'Sadie'
    rdoc.rdoc_files.include('lib/**/*.rb')
    rdoc.rdoc_files.include('README','TODO','CHANGELOG')
    rdoc.main = 'README'
    rdoc.rdoc_dir = 'rdoc'
end

def current_sadie_version
    version = "0.0.0"
    File.open("lib/sadie/version.rb","r").each do |line|
        if matches = line.match(/version\s*\=\s*\"([^\"]+)\"/i)
            version = matches[1]
            break
        end
    end    
    version
end
