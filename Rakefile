require 'rake'

# load rake tasks in lib/tasks (like it works in Rails)
tasklib_dirpath = File.join( File.dirname( __FILE__ ), 'lib', 'tasks' )
if Dir.exists? tasklib_dirpath
  Dir.entries( tasklib_dirpath ).each do |filename|
    load File.join( tasklib_dirpath, filename ) if ( filename =~ /\.rake$/ )
  end
end


