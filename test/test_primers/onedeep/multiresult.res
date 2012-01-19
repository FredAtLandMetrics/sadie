require 'sadie'

Sadie::Prime( "provides" =>     %w{ onedeep.multiresult.oneprime
                                onedeep.multiresult.twoprime } ) do |sadie|
    sadie.set( "onedeep.multiresult.oneprime", "primedthem" )
    sadie.set( "onedeep.multiresult.twoprime", "primedthem" )
end
