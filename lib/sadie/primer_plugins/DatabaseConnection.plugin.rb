# WARNING: THIS DOESN'T WORK YET!!!

Sadie::registerPrimerPlugin( {  "match" => /\.dbi\.conx$/,
                                "accepts-block" => false,
                                "prime-on-init" => false } ) do |sadie, key_prefix, primer_file_filepath|
    
    # determine key
    sadie_key = key_prefix+'.'+File.basename( primer_file_filepath )
    
    
    Sadie::prime( { "provides" => [ sadie_key ] }) do |sadie|
        
        if inihash = Sadie::iniFileToHash( primer_file_filepath )
            dbparams = Hash.new
            
            inihash.each do |section, section_hash|
                section.match(/^connection$/) \
                    or next
                section_hash.each do |key, value|
                    dbparams[key] = value
                end
            end
            
            if ! dbparams.empty?
                # validate dbistr
                dbparams.has_key?( 'dbistr' ) \
                    or raise 'requried connection::dbistr was not defined'
                
                # default user and pass to nil
                user = dbparams.has_key?('user') ? dbparams['user']: nil;
                pass = dbparams.has_key?('pass') ? dbparams['pass']: nil;
                
                # call connect with block
                require 'rubygems'
                require 'mysql'
                require 'dbi'
                
                dbh = DBI.connect( dbparams['dbistr'], user, pass )
                
                # determine key
                #sadie_key = key_prefix+'.'+File.basename( primer_file_filepath )
                
                puts "installing db connection: #{sadie_key}"
                
                sadie.set( sadie_key, dbh )
                
            end
        end
    end            
    
#     # build parameter hash
#     dbparams = Hash.new
#     inifile = Ini.new( primer_file_filepath )
#     inifile.each do | section, key_from_ini_file, value |
#         section.match(/^connection$/) \
#             or next
#         dbparams[key_from_ini_file] = value
#     end
#     
#     # validate dbistr
#     dbparams.has_key?( 'dbistr' ) \
#         or raise 'requried connection::dbistr was not defined'
#     
#     # default user and pass to nil
#     user = dbparams.has_key?('user') ? dbparams['user']: nil;
#     pass = dbparams.has_key?('pass') ? dbparams['pass']: nil;
#     
#     # call connect with block
#     require 'dbi'
#     DBI.connect( dbparams['dbistr'], user, pass, block )
end