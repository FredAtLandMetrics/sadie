Sadie::prime( "provides" =>     %w{ toplevel_destructonget.oneprime
                                    toplevel_destructonget.twoprime } ) do |sadie|
    puts "running destructonget primer..."
    timeobj = Time.now
    timeinsecs = timeobj.to_f
    sadie.set( "toplevel_destructonget.oneprime", "primedthem - #{timeinsecs}" )
    sadie.set( "toplevel_destructonget.twoprime", "primedthem" )
    sadie.setDestroyOnGet("toplevel_destructonget.oneprime")
end
