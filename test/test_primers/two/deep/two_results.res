Sadie::prime( { "provides"   =>  %w{    two.deep.two_results.firstkey \
                                        two.deep.two_results.secondkey } } ) do |sadie|
                                        
    #puts "priming two_results.res"
                                        
    sadie.set( "two.deep.two_results.firstkey",  "primedthem" )
    sadie.set( "two.deep.two_results.secondkey", "primedthem" )
end
