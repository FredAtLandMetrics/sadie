Sadie::registerPrimerPlugin( { "match" => /\.sql2ar$/,
                               "accepts-block" => false,
                               "prime-on-init" => false } ) do |sadie, key_prefix, primer_file_filepath|
    primer_file_basename = File.basename( primer_file_filepath )
    sadie_key = key_prefix + '.' + primer_file_basename
    sadie_key = sadie_key.gsub(/^\./,"")
    
    Sadie::prime( { "provides" => [ sadie_key ] }) do |sadie|
    
        if ( matches = primer_file_basename.match( /^(.*)\.([^\.]+)\.sql2ar$/ ) )
            dbi_sadie_key = key_prefix + '.' + matches[2] + ".dbi.conx"
#             puts "dbi_sadie_key: #{dbi_sadie_key}, connecting..."
            dbconx = sadie.get( dbi_sadie_key )
#             puts "dbconx: #{dbconx}"
            if ( dbconx = sadie.get( dbi_sadie_key ) )
#                 puts "  connected."
                if sql_query = Sadie::templatedFileToString( primer_file_filepath )
                    
                    sth = dbconx.prepare(sql_query)
                    sth.execute
                    
                    result = Array.new
                    while row = sth.fetch
                        result.push row.to_a
                    end
                    
                    
                    sadie.setExpensive( sadie_key, result )
                    
                    # Close the statement handle when done
                    sth.finish
                end
            end
        end
    end
end