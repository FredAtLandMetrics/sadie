require 'open-uri'
download_dirpath = File.join( File.dirname( __FILE__ ), 'download' )
opt_dirpath = File.join( File.dirname( __FILE__ ), 'opt' )
redis_version = '2.8.3'

namespace :development do

  desc "ensure download directory exists" 
  task :ensure_download_directory do
    Dir.mkdir download_dirpath unless Dir.exists?( download_dirpath )
  end
  
  desc "ensure opt directory exists" 
  task :ensure_opt_directory do
    Dir.mkdir opt_dirpath unless Dir.exists?( opt_dirpath )
  end
  
  desc "download redis source"
  task :download_redis_source => :ensure_download_directory do
    if File.exists?( File.join( download_dirpath, "redis-#{redis_version}.tar.gz" ) )
      puts "redis source tarball already downloaded...skipping (remove download/redis-#{redis_version}.tar.gz and re-run to force)"
    else
      print "Downloading redis source..."
      Dir.chdir download_dirpath
      open( "redis-#{redis_version}.tar.gz", 'wb' ) do |file|
        file << open("http://download.redis.io/releases/redis-#{redis_version}.tar.gz").read
      end
      puts "done."
    end
  end
  
  desc "install temporary redis installation"
  task :install_temp_redis => [ :ensure_opt_directory, :download_redis_source ] do
    Dir.chdir( opt_dirpath )
    system "tar xzf ../download/redis-#{redis_version}.tar.gz"
    Dir.chdir( File.join( opt_dirpath, "redis-#{redis_version}" ) )
    system "make"
  end
  
  desc "start temporary redis service"
  task :start_temp_redis do
    Dir.chdir( File.join( opt_dirpath, "redis-#{redis_version}" ) )
    system "src/redis-server"
  end
  
end
