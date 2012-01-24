Sadie::registerPrimerPlugin( {  "match" => /(\.res|\.res\.rb)$/,
                                "accepts-block" => true,
                                "prime-on-init" => false } ) do |sadie, key_prefix, primer_file_filepath, block|
    
    load( primer_file_filepath )
    
end
