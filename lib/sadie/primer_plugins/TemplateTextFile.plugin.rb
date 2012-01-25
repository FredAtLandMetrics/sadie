Sadie::registerPrimerPlugin( { "match" => /\.tmpl$/,
                               "accepts-block" => false,
                               "prime-on-init" => false } ) do |sadie, key_prefix, primer_file_filepath|
    primer_file_basename = File.basename( primer_file_filepath )
    sadie_key = key_prefix + '.' + primer_file_basename
    sadie_key = sadie_key.gsub(/^\./,"")
    
    Sadie::prime( { "provides" => [ sadie_key ] }) do |sadie|
    
        sadie.setExpensive( sadie_key, Sadie::templatedFileToString( primer_file_filepath ) )
    
    end
end