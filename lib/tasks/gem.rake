require "bundler/gem_tasks"

# increment version
desc "deploy a new gem"
task :deploy_gem => 'inc_version' do
    version = current_sadie_version
    sh "gem build sadie.gemspec"
    sh "gem push sadie-#{version}.gem"
end
