$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

require "test/unit"
require "sadie"
require "tmpdir"

class TestSadieTwoDeep < Test::Unit::TestCase
    def test_simple
        Dir.mktmpdir("sadie_testdir") do | dir |
            sadie = Sadie::getSadieInstance( {  "sadie.primers_dirpath" => "test/test_primers",
                                                "sadie.sessions_dirpath" => dir,
                                                "sadie.primer_plugins_dirpath" => "lib/sadie/primer_plugins" } )
            
            # test two-deep ini
            assert_equal( sadie.get( "two.deep.conf.section.thiskey" ), "thisval" )
            
            # test two-deep res
            assert_equal( sadie.get( "two.deep.two_results.firstkey" ), "primedthem" )
            assert_equal( sadie.get( "two.deep.two_results.secondkey" ), "primedthem" )
            
            # test two-deep expensive
            assert_equal( sadie.get( "expensive.oneprime" ), "primedit" )
            
            # test db connection
            dbconx = sadie.get( "two.deep.test.dbi.conx" )
            puts "dbconx(test): #{dbconx}"
            assert_not_nil( dbconx )
            assert_not_nil( sadie.get( "two.deep.testquery.test.sql" ) )
        end
    end
end