#$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
#$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
#$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift ENV["GEM_HOME"]

require "test/unit"
require "sadie"
require "tmpdir"

class TestSadieToplevel < Test::Unit::TestCase
    def test_simple
        Dir.mktmpdir("sadie_testdir") do | dir |
            sadie = Sadie::getSadieInstance( {  "sadie.primers_dirpath" => "test/test_primers",
                                                "sadie.sessions_dirpath" => dir,
                                                "sadie.primer_plugins_dirpath" => "lib/sadie/primer_plugins" } )
            sadie.initializePrimers
            
            # test eacher on non-intentional non-prime
            
#             te = sadie.get( "toplevel_testeach" )
#             puts "TE: #{te}"
            assert_equal( sadie.get( "toplevel_testeach" ), "blahbloo" ) 
            assert_equal( sadie.get( "toplevel_somegroup.eachtest" ), "blooblah" ) 
                          
            # test top-level ini
            assert_equal( sadie.get( "toplevel.somegroup.somekey"       ), "someval"    )
            assert_equal( sadie.get( "toplevel.anothergroup.anotherkey" ), "anotherval" )
            
            # test top-level res
            assert_equal( sadie.get( "toplevel_single.oneprime" ), "primedit" )
            
            # test destruct-on-get (or always prime)
            #   the primer sets .oneprime with the current time appended (to the millisecond)
            #   but it sets .twoprime the same each time.  the sleep insures that at least
            #   a millisecond has passed so that the value should be different the second time
            #   it gets set
            dog1a = sadie.get( "toplevel_destructonget.oneprime" )
            dog2a = sadie.get( "toplevel_destructonget.twoprime" )
            dog2b = sadie.get( "toplevel_destructonget.twoprime" )
            sleep( 0.01 )
            dog1b = sadie.get( "toplevel_destructonget.oneprime" )
            assert_equal( dog2a, dog2b )
            assert_not_equal( dog1a, dog1b )
            
        end
    end
end