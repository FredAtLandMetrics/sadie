# WARNING: THIS DOESN'T WORK YET!!!

Sadie::registerPrimerPlugin( {  "match" => /\.dbi\.conx$/,
                                "accepts-block" => true } ) do |sadie, key_prefix, primer_file_filepath, block|

    # build parameter hash
    dbparams = Hash.new
    inifile = Ini.new( primer_file_filepath )
    inifile.each do | section, key_from_ini_file, value |
        section.match(/^connection$/) \
            or next
        dbparams[key_from_ini_file] = value
    end
    
    # validate dbistr
    dbparams.has_key( 'dbistr' ) \
        or raise 'requried connection::dbistr was not defined'
    
    # default user and pass to nil
    user = dbparams.has_key('user') ? dbparams['user']: nil;
    pass = dbparams.has_key('pass') ? dbparams['pass']: nil;
    
    # call connect with block
    require 'dbi'
    DBI.connect( dbparams['dbistr'], user, pass, block )
end