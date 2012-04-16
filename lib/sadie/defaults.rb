# ==Notes
# this file sets defaults which can and should be overridden using arguments
# the sadie constructor

class Sadie
  DEFAULTS = {
    "sadie.primers_dirpath" => File.expand_path("primers","/var/sadie"),
    "sadie.sessions_dirpath" => File.expand_path("sessions","/var/sadie"),
    "sadie.primer_plugins_dirpath" => "lib/sadie/primer_plugins"
  }
end
