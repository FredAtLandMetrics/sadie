require 'sadie'

Sadie::Prime( "provides" =>  %w{ expensive.oneprime } ) do |sadie|
    sadie.setExpensive( "expensive.oneprime", "primedit" )
end
