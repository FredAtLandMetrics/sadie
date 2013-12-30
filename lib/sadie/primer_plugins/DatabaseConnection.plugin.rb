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
                require 'dbi'
                
                begin
                    dbh = DBI.connect( dbparams['dbistr'], user, pass )
                rescue DBI::DatabaseError => e
                    puts "A database connection error occurred..."
                    puts "  Error code: #{e.err}"
                    puts "  Error message: #{e.errstr}"
                    exit
                end
                
                sadie.set( sadie_key, dbh )
                
            end
        end
    end            
    

end