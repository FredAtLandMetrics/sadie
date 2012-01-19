require 'sadie'

Sadie::Prime( "provides" =>  %w{ toplevel_single.oneprime } ) do |sadie|
    sadie.set( "toplevel_single.oneprime", "primedit" )
end
