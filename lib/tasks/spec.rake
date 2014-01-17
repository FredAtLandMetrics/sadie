namespace :spec do
  
  desc "test config file"
  task :configtest do
    
    system "rspec spec/configtest.rb"
    
  end

  desc "test SadieConfig class"
  task :sadie_config do
    
    system "rspec spec/sadie_config.rb"
    
  end

end

