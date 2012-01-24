Sadie::registerPrimerPlugin( {  "match" => /\.ini$/,
                                "accepts-block" => false,
                                "prime-on-init" => true } ) do |sadie, key_prefix, primer_file_filepath|
    
    require 'ini'
    
    ini_file_basename = File.basename primer_file_filepath
    ini_file_root = ini_file_basename.gsub( /\.ini$/, "" )
    
    inifile = Ini.new( primer_file_filepath )
#      puts "key_prefix: #{key_prefix}, primer_file_filepath: #{primer_file_filepath}"
    inifile.each do | section, key_from_ini_file, value |
        
        # compute key
#         key_prefix = sadie.getCurrentPrimerKeyPrefix
        key_to_set =  key_prefix + "." + ini_file_root + "." +section + "." + key_from_ini_file
        key_to_set = key_to_set.gsub( /^\.+/, "" )
        
        sadie.set( key_to_set, value )
    end
end