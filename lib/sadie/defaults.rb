# ==Notes
# this file sets defaults which can and should be overridden using arguments
# the sadie constructor
require 'sadie/version'

class Sadie
    
  ppdp = File.join("lib/sadie/primer_plugins",File.join("gems/sadie-#{Sadie::VERSION}",ENV['GEM_HOME']))
  puts "ppdf: #{ppdp}"
  if ! File.exists? ppdp
      ppdp = "lib/sadie/primer_plugins"
  end
  
  DEFAULTS = {
    "sadie.primers_dirpath" => File.expand_path("primers","/var/sadie"),
    "sadie.sessions_dirpath" => File.expand_path("sessions","/var/sadie"),
    "sadie.primer_plugins_dirpath" => ppdp
  }
end
