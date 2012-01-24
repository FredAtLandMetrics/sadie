$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

require "test/unit"
require "sadie"
require "tmpdir"

class TestSadieToplevel < Test::Unit::TestCase
    def test_simple
        Dir.mktmpdir("sadie_testdir") do | dir |
            sadie = Sadie::getSadieInstance( {  "sadie.primers_dirpath" => "test/test_primers",
                                                "sadie.sessions_dirpath" => dir,
                                                "sadie.primer_plugins_dirpath" => "lib/sadie/primer_plugins" } )
            
            # test top-level ini
            assert_equal( sadie.get( "toplevel.somegroup.somekey"       ), "someval"    )
            assert_equal( sadie.get( "toplevel.anothergroup.anotherkey" ), "anotherval" )
            
            # test top-level res
            assert_equal( sadie.get( "toplevel_single.oneprime" ), "primedit" )
            
            # test destruct on get
            dog1a = sadie.get( "toplevel_destructonget.oneprime" )
            dog2a = sadie.get( "toplevel_destructonget.twoprime" )
            dog2b = sadie.get( "toplevel_destructonget.twoprime" )
            sleep( 2 )
            dog1b = sadie.get( "toplevel_destructonget.oneprime" )
            assert_equal( dog2a, dog2b )
            assert_not_equal( dog1a, dog1b )
        end
    end
end