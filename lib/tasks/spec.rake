namespace :spec do
  
  desc "test SadieConfig class"
  task :sadie_config do
    system "rspec spec/sadie_config.rb"
  end

  desc "test SadieStorageManager class"
  task :storage_manager do
    system "rspec spec/storage_manager.rb"
  end

end

