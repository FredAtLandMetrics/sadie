require 'sadie'

Sadie::Prime( { "provides"   =>  %w{    two.deep.two_results.firstkey \
                                        two.deep.two_results.secondkey } } ) do |sadie|
    sadie.set( "two.deep.two_results.firstkey",  "primedthem" )
    sadie.set( "two.deep.two_results.secondkey", "primedthem" )
end
