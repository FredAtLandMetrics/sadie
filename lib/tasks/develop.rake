require 'open-uri'
download_dirpath = File.join( File.dirname( __FILE__ ), 'download' )
redis_version = '2.8.3'

namespace :development do

  desc "ensure download directory exists" 
  task :ensure_download_directory do
    Dir.mkdir download_dirpath unless Dir.exists?( download_dirpath )
  end
  
  desc "download redis source"
  task :download_redis_source => :ensure_download_directory do
    print "Downloading redis source..."
    Dir.chdir download_dirpath
    open( "redis-#{redis_version}.tar.gz", 'wb' ) do |file|
      file << open("http://download.redis.io/releases/redis-#{redis_version}.tar.gz").read
    end
    puts "done."
  end
  
end
