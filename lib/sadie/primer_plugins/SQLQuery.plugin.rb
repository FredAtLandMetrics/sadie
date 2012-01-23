# requires dbconx plugin to be installed as well

require 'sadie'

Sadie::registerPrimerPlugin( { "match" => /\.sql$/,
                               "accepts-block" => true } ) do |sadie, primer_file_filepath, block|

    # read query from file @filepath, ditch newlines
    f = open( primer_file_filepath )
    query = f.read
    close( f )
    query = query.gsub(/\n/,'')
    
    # get the database and run query
    db_key = Sadie::pathToKey( primer_file_filepath, 1 ) 
    sadie.get( db_key ) do | dbh |
        
        # run the query
        dbh.select_all( query, block )        
        
    end
    raise 'Sadie returned nil for key: #{db_key}'
end