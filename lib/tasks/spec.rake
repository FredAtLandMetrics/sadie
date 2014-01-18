namespace :spec do
  
  desc "test SadieConfig class"
  task :sadie_config do
    system "rspec spec/sadie_config.rb"
  end

  desc "test SadieStorageManager class"
  task :storage_manager do
    system "rspec spec/storage_manager.rb"
  end

  desc "test SadieStorageManagerLockManager class"
  task :storage_manager_lock_manager do
    system "rspec spec/storage_manager_lock_manager.rb"
  end

  desc "test sadie classes with redis connectivity"
  task :sadie_redis do
    system "rspec spec/sadie_redis.rb"
  end

  desc "extensively test sadie classes with redis connectivity"
  task :sadie_redis_extensive do
    system "SADIE_REDIS_EXTENSIVE=1 rspec spec/sadie_redis.rb"
  end

end

