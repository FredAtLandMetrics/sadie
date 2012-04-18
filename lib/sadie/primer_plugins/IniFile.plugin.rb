Sadie::registerPrimerPlugin( {  "match" => /\.ini$/,
                                "accepts-block" => false,
                                "prime-on-init" => true } ) do |sadie, key_prefix, primer_file_filepath|
    
    puts "processing ini file: #{primer_file_filepath}"
    
    ini_file_basename = File.basename primer_file_filepath
    ini_file_root = ini_file_basename.gsub( /\.ini$/, "" )
    
    if inihash = Sadie::iniFileToHash( primer_file_filepath )
        inihash.each do |section, section_hash|
            section_hash.each do |key, value|
                key_to_set =  key_prefix + "." + ini_file_root + "." + section + "." + key
                key_to_set = key_to_set.gsub(/^\./,"")
                sadie.set( key_to_set, value )
                
            end  
        end
    end
    
end