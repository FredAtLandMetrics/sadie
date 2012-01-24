# WARNING: THIS DOESN'T WORK YET!!!

Sadie::registerPrimerPlugin( { "match" => /\.sql$/,
                               "accepts-block" => true } ) do |sadie, key_prefix, primer_file_filepath, block|

    # read query from file @filepath, ditch newlines
    f = open( primer_file_filepath )
    query = f.read
    close( f )
    query = query.gsub(/\n/,'')
    
    # get the database and run query
    db_key = key_prefix+".db.conx"
    sadie.get( db_key ) do | dbh |
        
        # run the query
        dbh.select_all( query, block )
        
    end
    raise 'Sadie returned nil for key: #{db_key}'
end