# requires dbconx plugin to be installed as well

require 'sadie'

Sadie::registerPrimerPlugin( { "match" => /\.ini$/,
                                "accepts-block" => false } ) do |sadie, primer_file_filepath|

    inifile = Ini.new( primer_file_filepath )
    inifile.each do | section, key_from_ini_file, value |
        
        # compute key
        key_to_set =  key_prefix + "." + section + "." + key_from_ini_file
        key_to_set = key_to_set.gsub( /^\.+/, "" )
        #puts "key_to_set: #{key_to_set}"
        
        # get sadie instance and set
        sadie = Sadie::_getCurrentSadieInstance
        sadie.set( key_to_set, value )
    end
end