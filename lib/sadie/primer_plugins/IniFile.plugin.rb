Sadie::registerPrimerPlugin( {  "match" => /\.ini$/,
                                "accepts-block" => false,
                                "prime-on-init" => true } ) do |sadie, key_prefix, primer_file_filepath|
    
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
    
#     section = nil
#     File.open( primer_file_filepath, "r" ).each do |f|
#         f.each_line do |line|
#             next if line.match(/^;/) # skip comments
#             if matches = line.match(/\[([^\]]+)\]/)
#                 section = matches[1]
#             elsif matches = line.match(/^\s*([^\s\=]+)\s*\=\s*([^\s]+)\s*$/)
#                 key = matches[1]
#                 value = matches[2]
#                 if qmatches = value.match(/[\'\"](.*)[\'\"]/)
#                     newvalue = qmatches[1]
#                     value = newvalue
#                 end
#                 if defined? section
#                     key_to_set =  key_prefix + "." + ini_file_root + "." +section + "." + key
#                     sadie.set( key_to_set, value )
#                 end
#             end
#         end
#     end
    
#     require 'rubygems'
#     require 'ini'
#     
#     ini_file_basename = File.basename primer_file_filepath
#     ini_file_root = ini_file_basename.gsub( /\.ini$/, "" )
#     
#     inifile = Ini.new( primer_file_filepath )
# #      puts "key_prefix: #{key_prefix}, primer_file_filepath: #{primer_file_filepath}"
#     inifile.each do | section, key_from_ini_file, value |
#         
#         # compute key
# #         key_prefix = sadie.getCurrentPrimerKeyPrefix
#         key_to_set =  key_prefix + "." + ini_file_root + "." +section + "." + key_from_ini_file
#         key_to_set = key_to_set.gsub( /^\.+/, "" )
#         
#         sadie.set( key_to_set, value )
#     end
end