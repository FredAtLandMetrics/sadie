Sadie::registerPrimerPlugin( { "match" => /\.sql2ar$/,
                               "accepts-block" => false,
                               "prime-on-init" => false } ) do |sadie, key_prefix, primer_file_filepath|
    primer_file_basename = File.basename( primer_file_filepath )
    sadie_key = key_prefix + '.' + primer_file_basename
    sadie_key = sadie_key.gsub(/^\./,"")
    puts "DEFINING sql2ar primer for: #{sadie_key}"
    Sadie::prime( { "provides" => [ sadie_key ] }) do |sadie|
        puts "priming via sql2ar for: #{sadie_key}"
        if ( matches = primer_file_basename.match( /^(.*)\.([^\.]+)\.sql2ar$/ ) )
            dbi_sadie_key = key_prefix + '.' + matches[2] + ".dbi.conx"
            dbconx = sadie.get( dbi_sadie_key )
            if ( dbconx = sadie.get( dbi_sadie_key ) )
                if sql_query = Sadie::templatedFileToString( primer_file_filepath )
                    
                    sth = dbconx.prepare(sql_query)
                    sth.execute
                    
                    
                    puts "looping thru db query results"
                    result = Array.new
                    while row = sth.fetch
                        row_as_array = row.to_a
                        puts "calling eacherFrame each for sadiekey: #{sadie_key}"
                        Sadie::eacherFrame sadie_key, Sadie::EACH, row_as_array
                        result.push row_as_array
                    end
                    
                    sadie.setExpensive( sadie_key, result )
                    
                    # Close the statement handle when done
                    sth.finish
                end
            end
        end
    end
end