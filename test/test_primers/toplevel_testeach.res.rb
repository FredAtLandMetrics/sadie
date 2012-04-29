Sadie::prime( "provides" =>     %w{ toplevel_testeach } ) do |sadie|
    sadie.get "toplevel_double.twoprime"
    sadie.set( "toplevel_testeach", sadie.get( "toplevel_double.eachtest" ) )
end
