namespace :spec do
  
  namespace :v2 do
    desc "run all spec tests"
    task :all => [ 'spec:sadie_server_lib', 'spec:storage_mechanism:memory',
                  'spec:storage_mechanism:memory', 'spec:primer', 'spec:storage_manager',
                  'spec:session', 'spec:server' ]do
      a = 1 # a do nothing statement
    end
    
    desc "redis based sadie"
    task :redis do
      system "rspec spec/v2/sadie_redis.rb"
    end
    
    desc "test sadie server library"
    task :sadie_server_lib do
      system "rspec spec/v2/sadie_server_lib.rb"
    end
    
    namespace :storage_mechanism do
      desc "test the memory-based storage mechanism"
      task :memory do
        system "rspec spec/v2/storage_mechanisms/memory.rb"
      end
      desc "test the file-based storage mechanism"
      task :file do
        system "rspec spec/v2/storage_mechanisms/file.rb"
      end
    end
    
    desc "test primer"
    task :primer do
      system "rspec spec/v2/primer.rb"
    end
    
    desc "test timestamp queue"
    task :timestamp_queue do
      system "rspec spec/v2/timestamp_queue.rb"
    end
    
    desc "test lock_manager"
    task :lock_manager do
      system "rspec spec/v2/lock_manager.rb"
    end
    
    desc "test storage manager"
    task :storage_manager do
      system "rspec spec/v2/storage_manager.rb"
    end
    
    desc "test session"
    task :session do
      system "rspec spec/v2/sadie_session.rb"
    end
    
    desc "test session with timers (slow)"
    task :session_with_timers do
      system "SADIE_SESSION_TEST_TIMERS=1 rspec spec/v2/sadie_session.rb"
    end
    
    desc "test RESTful server"
    task :server do
      system "rspec spec/v2/sadie_server.rb"
    end
  end
end

