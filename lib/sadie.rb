# this requires the gem: ini
require 'rubygems'
require "bundler/setup"
require 'bundler'
Bundler.require(:default)
#require 'ini'


# ==Description: Sadie
# Sadie is a data framework intended to ease the pain of constructing, accessing, and 
# managing the resources required by large stores of inter-related data. It supports
# sessions, lazy on-demand, one-time evaluation and file-based storage/retrieval
# operations for resource-heavy data.
# 
# For simplicity, it supports simple, ini-style data
# initialization, but for efficient optimization of resource-intensive computations, it
# supports on-demand, one-time evaluation of &quot;primers&quot; which may define, or prime,
# multiple key, value pairs in a single run.

class Sadie
    
    
    # ==method: constructor
    #   options can include any kay, value pairs but the following key values bear mention:
    #     REQUIRED
    #
    #       sadie.sessions_dirpath
    #           or
    #         sadie.session_id
    #           or
    #         sadie.session_filepath  <- this is probably a bad call, use with caution
    #     
    #       and
    #
    #       sadie.primers_dirpath
    def initialize( options )
        
        # start with blank slate short-term memory, primed and expensive flag hashes
        @shortterm                      = Hash.new
        @flag_expensive                 = Hash.new
        @flag_primed                    = Hash.new
        @flag_eachtimeprime             = Hash.new

        # init class
        Sadie::_checkSanity
        
        # init mid_primer_initialization if not already done
        if ! defined? @@mid_primer_initialization
            @@mid_primer_initialization = false
            @@mid_primer_filepath       = nil
            @@mid_primer_toplevel_primer_dirpath = nil
        end
        
        # internalize defaults to shortterm
        DEFAULTS.each do |key, value|
            _set( key, value )
        end
        
        # internalize supplied defaults
        options.each do |key, value|
            set( key, value )
        end
        
        # if a path to a session is given, init using session file
        if defined? options[:sadie.session_filepath] && options[:sadie.session_filepath].match(/^[^\s]+$/)
            set( "sadie.session_filepath", options[:sadie.session_filepath] )
            _initializeWithSessionFilePath( get("sadie.session_filepath") )
            return
        end
        
        # determine session id, init from session if provided as arg
        if defined?options[:sadie.session_id] && options[:sadie.session_id].match(/^[^\s]+$/)
            set( "sadie.session_id", options[:sadie.session_id] )
            _initializeWithSessionId( get( "sadie.session_id" ) )
        else
            set( "sadie.session_id", _generateNewSessionId )
        end
        
    end
    
    # ==method: Sadie::getSadieInstance
    #
    # returns a new Sadie instance.  Options match those of Sadie's constructor method
    def self.getSadieInstance( options )
        Sadie.new(options)
    end

    # ==method: Sadie::Prime
    #
    # called my the .res files to register the keys the .res will prime for
    # 
    # accepts as an argument a hash and a block.  The hash must include the key:
    # 'provides' and it must define an array
    # of keys that the calling resource (.res) file will have provided after the block is
    # evaluated
    def self.Prime ( primer_definition )
        
        # validate params
        defined? primer_definition \
            or raise "Prime called without parameters"
        primer_definition.is_a? Hash \
            or raise "Prime called without hash parameters"
        defined? primer_definition["provides"] \
            or raise "Prime called without provides parameter"
        
        # if initializing primers, just remember how to get back to the primer later,
        # otherwise, prime
        if Sadie::_midPrimerInit?
            
            # mid primer init, just memorize primer location
            Sadie::_memorizePrimerLocation( @@mid_primer_filepath,  primer_definition["provides"] )
        else
            
            # run code block with the current sadie instance
            current_sadie_instance = Sadie::_getCurrentSadieInstance
            yield( current_sadie_instance )
            
            # loop thru all primer provides, ensuring each primed
            current_primer_filepath = Sadie::_getCurrentPrimerFilepath
            primer_definition["provides"].each do | key |
                
                # skip blank lines
                next if key.match /^\s*$/
                
                #puts "Prime> providing: #{key}"
                
                # key primed or raise error
                current_sadie_instance.primed? key \
                    or raise "primer definition file: #{current_primer_filepath} was supposed to define #{key}, but did not"
            end
        end
    end
    
    # ==method: get
    #
    # a standard getter which primes the unprimed and recalls "expensive" facts from files
    # completely behind-the-scenes as directed by the resource (.res) files
    def get( k )
        
        # if it's already set, return known answer
        if _isset?( k )
            
            # _get the return value
            return_value = _get( k )
            
            # unset and unprime if destructOnGet?
            if destructOnGet?( k )
#                 puts "destructing #{k}"
                unset( k )
                unprime( k )
            end
            
            return return_value
        end
        
        # prime if not yet primed
        primed?( k ) \
            or _prime( k )
            
        # if not expensive, then return what's already known
        expensive?( k ) \
            and return _recallExpensive( k )
            
        # _get the return value
        return_value = _get( k )
        
        # unset and unprime if destructOnGet?
        if destructOnGet?( k )
#                 puts "destructing #{k}"
            unset( k )
            unprime( k )
        end
        
        return return_value
    end
    
    
    # ==method: setCheap
    #
    # the expensive setter.  key, value pairs stored via this method are not kept in memory
    # but are stored to file and recalled as needed
    def setExpensive(k,v)
        expensive_filepath              = _computeExpensiveFilepath( k )
        serialized_value                = Marshal::dump( v )
        File.open(expensive_filepath, 'w') { |f|
            f.write( serialized_value )
        }
        _expensive( k, true )
        _primed( k, true )
    end
    
    # ==method: setDestructOnGet
    #
    #    key value will go away and key will be unprimed and unset after next get
    #
    #    NOTE: this doesn't make sense with keys that were set via setExpensive
    #          so it can be set, but nothing's going to happen differently
    def setDestructOnGet( key, turnon=true )
#         puts "setDestructOnGet( #{key}, #{turnon} )"
        if ( turnon )
#             puts "turning on destructOnGet for key: #{key}"
            @flag_eachtimeprime["#{key}"] = true
            return true
        end
        @flag_eachtimeprime.has_key?( key ) \
            and @flag_eachtimeprime.delete( key )
    end
    
    # ==method: destructOnGet?
    #
    # returns true if the destructOnGet flag is set for the key
    def destructOnGet?( key )
#         print "destructOnGet?> key #{key} "
        @flag_eachtimeprime.has_key?( key ) \
            or return _newline( false )
#         print " defined-in-eachtimeprime "
        @flag_eachtimeprime["#{key}"] \
            and return _newline( true )
#         print " defined-but-false "
        return _newline(false)
    end
    
    def _newline( rval=true )
        #puts
        return rval
    end
    
    # ==method: unset
    # unsets the value of k.  Note that this does not unprime, so
    # get(key) will simply return nil. Run with unprime to have the
    # primer run again
    def unset( key )
        _unset( key )
    end
    
    # ==method: unprime
    # unprimes k.  Note that this does not unset the value, so
    # get(key) will continue to return whatever it otherwise would have.
    # run unset as well to have the primer run again.
    def unprime( key )
        _primed( key, false )
    end
    
    # ==method: set
    # alias for setCheap(k,v)
    def set( k, v )
        setCheap( k, v )
    end
    
    # ==method: setCheap
    #
    # the cheap setter.  key, value pairs stored via this method are kept in memory
    def setCheap( k, v )
        
        # set it, mark not expensive and primed
        _set( k, v )
        _expensive( k, false )
        _primed( k, true )
        
        # if we've reset the primers dirpath, init the primers
        if k.eql?( "sadie.primers_dirpath" )
            Sadie::_setMidPrimerTopLevelPrimersDirpath( v )
            Sadie::_setCurrentSadieInstance( self )
            Sadie::_init_primers
        end
        
    end
    
    # ==method: save
    #
    # serialize to session file
    def save
        session_filepath = File.expand_path( "session."+value, get( "sadie.sessions_dirpath" ) )
        serialized_value                = Marshal::dump( [ @shortterm, @flag_primed, @flag_expensive ] )
        File.open(session_filepath, 'w') { |f|
            f.write( serialized_value )
        }        
    end
    
    # ==method: revert!
    #
    # return to last saved state
    #
    def revert!
        
        @shortterm = {
            "sadie.session_id"                => get( "sadie.session_id" ),
            "sadie.sessions_dirpath"          => get( "sadie.sessions_dirpath" )
        }
        
        _initializeWithSessionId( get( "sadie.session_id" ) )
    end
    
    # ==method: primed?
    #
    #   INTERNAL: this method should only be called the the class method, Prime
    #
    def primed?( k )
        @flag_primed.has_key?( k ) \
            or return false
        @flag_primed["#{k}"] \
            and return true
        return false
    end
    
    # ==method: primed?
    #
    #   INTERNAL: this method should only be called the the class method, Prime
    #
    def expensive?( k )
        @flag_expensive.has_key?( k ) or return false;
        @flag_expensive["#{k}"] \
            and return true
        return false
    end
    
    
    
    private
    
    
    def _prime ( k )
#         puts "_prime( #{k} )"
        # fetch primers dirpath and validate the primer hash
        primer_dirpath = _get("sadie.primers_dirpath")
        @@primer_hash.has_key?(primer_dirpath) \
            or @@primer_hash[primer_dirpath] = Hash.new
        
        primers = @@primer_hash[primer_dirpath]
        primers.has_key?( k ) or return true
                
        if primer_filepath = primers[k]
#             puts "loading filepath: #{primer_filepath}"
            Sadie::_setCurrentPrimerFilepath(primer_filepath)
            Sadie::_setCurrentSadieInstance( self )
            load primer_filepath
        end
        return true
        
    end
    
    def self._setCurrentPrimerFilepath ( filepath )
        @@current_primer_filepath = filepath
    end
    
    def self._getCurrentPrimerFilepath
        @@current_primer_filepath
    end
    
    def self._setCurrentSadieInstance ( instance )
        @@current_sadie_instance = instance
    end
    
    def self._getCurrentSadieInstance
        @@current_sadie_instance
    end
    
    
    def self._init_primers( key_prefix="", current_dirpath="" )
        
        # default to the top-level primers dirpath
        if current_dirpath.empty?
            sadie_instance = Sadie::_getCurrentSadieInstance
            current_dirpath = sadie_instance.get( "sadie.primers_dirpath" ) \
                or raise "sadie.primers_dirpath not set"
        end
        
        
            
        # loop thru each file in the directory, recurse into subdirs and
        # process known filetypes
        Dir.foreach( current_dirpath ) do |filename|
            
            filepath = File.expand_path( filename, current_dirpath )
            
            if File.directory?( filepath )
                
                # recurse
                filename.eql?(".") || filename.eql?("..") \
                    or Sadie::_init_primers( key_prefix + "." + filename,  filepath )
            else
                
                # proc known filetypes
                if matches = filename.match( /^(.*)\.ini$/ )
                    prefix = key_prefix + "." + matches[1]
                    prefix.gsub( /^\.+/, "" )
                    
                    Sadie::_init_primers_proc_ini_file( prefix, filepath )
                elsif filename.match( /\.res$/ ) || filename.match( /\.res.rb$/ )
                    Sadie::_init_primers_proc_res_file( filepath )
                end
            end
        end
    end
    
    def self._init_primers_proc_ini_file( key_prefix, filepath )
        inifile = Ini.new( filepath )
        inifile.each do | section, key_from_ini_file, value |
            
            # compute key
            key_to_set =  key_prefix + "." + section + "." + key_from_ini_file
            key_to_set = key_to_set.gsub( /^\.+/, "" )
            #puts "key_to_set: #{key_to_set}"
            
            # get sadie instance and set
            sadie_instance = Sadie::_getCurrentSadieInstance
            sadie_instance.set( key_to_set, value )
        end
    end
    
    def self._init_primers_proc_res_file( filepath )
        
#         puts "Loading #{filepath}..."
        
        # load the res file
        Sadie::_setMidPrimerInit( filepath )
        load( filepath )
        Sadie::_unsetMidPrimerInit
        
    end
    
    def _recallExpensive( k )
        expensive_filepath              = _computeExpensiveFilepath( k )
        File.exists? expensive_filepath \
            or raise "expensive filepath: #{filepath} does not exist"
        f = open( expensive_filepath )
        v  = Marshal::load( f.read )
        
        return v
    end
    
    def _computeExpensiveFilepath( k )
        session_id = get( "sadie.session_id" )
        File.expand_path("session."+session_id+".exp."+k, _get( "sadie.sessions_dirpath" ) )
    end
    
    def _primed( k, isprimed )
        if isprimed
            @flag_primed["#{k}"]       = true
            return
        end
        @flag_primed.delete( k )
    end
    
    def _expensive( k, isexpensive )
        if isexpensive
            @flag_expensive["#{k}"]    = true
            return
        end
        @flag_expensive.delete( k )
    end
    
    # direct access getter for shortterm memory
    def _get( key )
        value = @shortterm["#{key}"]
        #puts "_get(#{key})> #{value}"
        return value
    end
    
    # direct access setter for shortterm memory
    def _set( key, value )
        
#        puts "_set> key: #{key}, value: #{value}"
        @shortterm["#{key}"]           = value
    end
    
    def _unset( key )
        @shortterm.has_key?( key ) \
            and @shortterm.delete( key )
    end
    
    def _isset?( key )
        return @shortterm.has_key?( key )
    end
    
    # init given path to session file
    def _initializeWithSessionFilePath(session_filepath)
        
        # bail on non-existant file
        File.exist?( session_filepath ) \
            or raise "session file, " + session_filepath + " does not exist"
            
        # open session file and read internal vars from it
        File.open( session_filepath, "r" ).each do |f|
            
            # make sure no writing happens while we read
            f.flock(File::Lock_SH)
            
            # read vars from file
            mem, primed, expensive = Marshal::load( f.read )
        end
        
        # destructive set on flag vars
        @flag_primed                = primed
        @flag_expensive             = expensive
        
        # additive set on shortterm mem
        mem.each do |k,v|
            set(k, v)
        end
    end
    
    # init given session id               
    def _initializeWithSessionId(session_id)
        session_filepath = File.expand_path( "session."+session_id, get( "sadie.sessions_dirpath" ) )
        _initializeWithSessionFilePath(session_filepath)
    end
        
    # gen new session id
    def _generateNewSessionId
        begin
            value = ""
            24.times{value  << (65 + rand(25)).chr}
        end while File.exist?(File.expand_path("session."+value, get( "sadie.sessions_dirpath" ) ) )
        return value
    end
    
    def self._setMidPrimerInit ( filepath )
        @@mid_primer_initialization     = true
        @@mid_primer_filepath           = filepath
    end
    
    def self._unsetMidPrimerInit
        @@mid_primer_initialization     = false
    end
    
    def self._midPrimerInit?
        @@mid_primer_initialization
    end
    
    def self._memorizePrimerLocation( filepath, primer_provides )
        primer_dirpath = @@mid_primer_toplevel_primer_dirpath
        @@primer_hash.has_key?( primer_dirpath ) \
            or @@primer_hash["#{primer_dirpath}"] = Hash.new
        primer_provides.each do | key |
            Sadie::_setPrimerProvider( key, filepath )
        end
    end
    
    def self._setMidPrimerTopLevelPrimersDirpath( dirpath )
        @@mid_primer_toplevel_primer_dirpath = dirpath
    end
    
    def self._setPrimerProvider( primer_name, primer_filepath )
        primer_dirpath = @@mid_primer_toplevel_primer_dirpath
        @@primer_hash["#{primer_dirpath}"]["#{primer_name}"] = primer_filepath
    end
    
    def self._checkSanity
        if ! defined? @@primer_hash
            @@primer_hash               = Hash.new
        end
        
    end
end

require "sadie/version"
require "sadie/defaults"

