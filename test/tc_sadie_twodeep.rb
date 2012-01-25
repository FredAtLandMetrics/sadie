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
            assert_not_nil( dbconx )
            
            # test sql22darray
            tablearray = sadie.get( "two.deep.testquery.test.sql" )
            assert_not_nil( tablearray )
            assert_equal( tablearray[0][0], 1 )
            assert_equal( tablearray[1][1], "testing456" )

            # test templating
            template_text = sadie.get( "two.deep.test_template.txt.tmpl" )
            template_text = template_text.gsub(/\s+/," ").gsub(/^\s*/,"").gsub(/\s*$/,"")
#             puts "template text\n#{template_text}"
            assert( (template_text.match(/later\s+gator/)), "incorrect match on template text" )
            assert( (template_text.match(/test\/test\_primers/)), "incorrect match on template text" )
        end
    end
end