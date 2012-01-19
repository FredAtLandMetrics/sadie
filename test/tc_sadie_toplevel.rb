$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

require "test/unit"
require "sadie"
require "tmpdir"

class TestSadieToplevel < Test::Unit::TestCase
    def test_simple
        Dir.mktmpdir("sadie_testdir") do | dir |
            sadie = Sadie::getSadieInstance( {  "sadie.primers_dirpath" => "test/test_primers",
                                                "sadie.sessions_dirpath" => dir                    } )
            
            # test top-level ini
            assert_equal( sadie.get( "toplevel.somegroup.somekey"       ), "someval"    )
            assert_equal( sadie.get( "toplevel.anothergroup.anotherkey" ), "anotherval" )
            
            # test top-level res
            assert_equal( sadie.get( "toplevel_single.oneprime" ), "primedit" )
        end
    end
end