require 'sadie'

Sadie::Prime( "provides" =>     %w{ toplevel_double.oneprime
                                toplevel_double.twoprime } ) do |sadie|
    sadie.set( "toplevel_double.oneprime", "primedthem" )
    sadie.set( "toplevel_double.twoprime", "primedthem" )
end
