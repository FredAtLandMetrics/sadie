# this requires the gem: ini
require 'rubygems'
require "bundler/setup"
require 'bundler'
Bundler.require(:default)
require 'erb'

# ==Description: Sadie
# Sadie is a data framework intended to ease the pain of constructing, accessing, and 
# managing the resources required by large stores of inter-related data. It supports
# sessions, lazy, on-demand, one-time evaluation and file-based storage/retrieval
# operations for resource-heavy data.
# 
# For simplicity, it supports simple, ini-style data
# initialization, but for efficient optimization of resource-intensive computations, it
# supports on-demand, one-time evaluation of &quot;primers&quot; which may define, or prime,
# multiple key, value pairs in a single run.

def S( key )
    instance = Sadie::getCurrentSadieInstance
    return instance.get( key )
end

class Sadie
    
    # ==method: Sadie::getSadieInstance
    #
    # returns a new Sadie instance.  Options match those of Sadie's constructor method
    def self.getSadieInstance( options )
        Sadie.new(options)
    end

    # ==method: Sadie::setCurrentSadieInstance
    #
    # this is called just prior to calling a primer plugin to handle a primer to provide
    # a current sadie instance for Sadie::getCurrentSadieInstance to return
    def self.setCurrentSadieInstance ( instance )
        @@current_sadie_instance = instance
    end
    
    # ==method: Sadie::setCurrentSadieInstance
    #
    # called by plugin handlers to get access to the current Sadie instance
    def self.getCurrentSadieInstance
        @@current_sadie_instance
    end    
    
    # ==method: Sadie::Prime
    #
    # called my the .res files to register the keys the .res will prime for
    # 
    # accepts as an argument a hash and a block.  The hash must include the key:
    # 'provides' and it must define an array
    # of keys that the calling resource (.res) file will have provided after the block is
    # evaluated
    def self.prime ( primer_definition, &block )
        current_sadie_instance = Sadie::getCurrentSadieInstance
        current_sadie_instance.prime( primer_definition, &block )
    end
    
    # ==method: Sadie::registerPrimerPlugin
    #
    # this method is called in the .plugin.rb files to register new plugin types
    #
    def self.registerPrimerPlugin ( arghash, &block )
        current_sadie_instance = Sadie::getCurrentSadieInstance
        current_sadie_instance.registerPrimerPlugin( arghash, &block )
    end
    
    # ==method: Sadie::iniFileToHash
    #
    # utility class method.  accepts a filepath.  digests ini file and returns hash of hashes.
    #
    def self.iniFileToHash ( filepath )
        section = nil
        ret = Hash.new
        File.open( filepath, "r" ).each do |f|
            f.each_line do |line|
                next if line.match(/^;/) # skip comments
                if matches = line.match(/\[([^\]]+)\]/)
                    section = matches[1]
                    ret[section] = Hash.new
                elsif matches = line.match(/^\s*([^\s\=]+)\s*\=\s*([^\s]+)\s*$/)
                    key = matches[1]
                    value = matches[2]
                    
                    # strip quotes
                    if qmatches = value.match(/[\'\"](.*)[\'\"]/)
                        value = qmatches[1]
                    end
                    
                    if defined? section
                        ret[section][key] = value
                    end
                end
            end
        end
        ret.empty? and return nil
        return ret
    end
    
    def self.templatedFileToString( filepath )
        f = open( filepath )
        template = ERB.new( f.read )
        template.result
    end

    
    # ==method: constructor
    #   options can include any kay, value pairs but the following key values bear mention:
    #     REQUIRED
    #
    #       sadie.sessions_dirpath
    #             or
    #           sadie.session_id
    #             or
    #           sadie.session_filepath  <- this is probably a bad call, use with caution
    #     
    #       and
    #
    #         sadie.primers_dirpath
    #
    #       and
    #         sadie.primer_plugins_dirpath
    def initialize( options )
        
        # check instance sanity
        _checkInstanceSanity        
        _checkClassSanity
        
        # internalize defaults to shortterm
        DEFAULTS.each do |key, value|
            if key.eql? "sadie.primer_plugins_dirpath"
                addPrimerPluginsDirPath value 
            else
                _set( key, value )
            end
        end
        
        # internalize supplied defaults, postponing a set of sadie.primers_dirpath
        # until the end if one is supplied.  The reason for this is that the setter
        # attempts to read the plugins and if the primer plugin dirpath has not
        # yet been set, then it'll choke if it processes the wrong one first
        delay_set_primers_dirpath = nil
      
        # iterate over constructor args, but do primers_dirpath last since it
        # causes a call to initializePrimers
        options.each do |key, value|
            if ( key.eql? "sadie.primers_dirpath")
                delay_set_primers_dirpath = value
            else
                set( key, value )
            end
        end
        defined? delay_set_primers_dirpath \
            and set( "sadie.primers_dirpath", delay_set_primers_dirpath )
        
        # if a path to a session is given, init using session file
        if options.has_key?( "sadie.session_filepath" )
            set( "sadie.session_filepath", options["sadie.session_filepath"] )
            _initializeWithSessionFilePath( get("sadie.session_filepath") )
        elsif options.has_key?( "sadie.session_id" )
            set( "sadie.session_id", options["sadie.session_id"] )
            _initializeWithSessionId( get( "sadie.session_id" ) )
        else
            set( "sadie.session_id", _generateNewSessionId )
        end
        
        
    end
    
    def addPrimerPluginsDirPath( path )
        
        exppath = File.expand_path(path)
        
        # add the path to the system load path
        $LOAD_PATH.include?(exppath) \
            or $LOAD_PATH.unshift(exppath)
            
        # add the path to the pluginsdir array
        defined? @plugins_dir_paths \
            or @plugins_dir_paths = Array.new        
        @plugins_dir_paths.include?(exppath) \
            or @plugins_dir_paths.unshift(exppath)
    end
    
   
    
    def prime( primer_definition, &block )
        # validate params
        defined? primer_definition \
            or raise "Prime called without parameters"
        primer_definition.is_a? Hash \
            or raise "Prime called without hash parameters"
        defined? primer_definition["provides"] \
            or raise "Prime called without provides parameter"
        
        # if initializing primers, just remember how to get back to the primer later,
        # otherwise, prime
        if midPrimerInit?
            
            # mid primer init, just memorize primer location
            memorizePrimerLocation( @@mid_primer_filepath, getCurrentPrimerPluginFilepath, primer_definition["provides"] )
        else
            
            # run code block with the current sadie instance
            block.call( self )
            
            # loop thru all primer provides, ensuring each primed
            current_primer_filepath = getCurrentPrimerFilepath
            primer_definition["provides"].each do | key |
                
                # skip blank lines
                next if key.match /^\s*$/
                
                #puts "Prime> providing: #{key}"
                
                # key primed or raise error
                primed? key \
                    or raise "primer definition file: #{current_primer_filepath} was supposed to define #{key}, but did not"
            end
        end
        
    end

    def registerPrimerPlugin ( arghash, &block )
        
        # if mid plugin init is set, we're registering the plugin
        # init mode, just store arghash info
        accepts_block = arghash.has_key?( "accepts-block" ) && arghash["accepts-block"] ? true : false
        prime_on_init = arghash.has_key?( "prime-on-init" ) && arghash["prime-on-init"] ? true : false
        
        
        
        
        
        # if mid plugin init, register the plugin params with the match
        if midPluginInit?
            
            regPluginMatch( arghash["match"], @@mid_plugin_filepath, accepts_block, prime_on_init )
            
        # midplugininit returned false, we're actually in the process of either initializing
        # a primer or actually priming
        else
            yield( self, getCurrentPrimerKeyPrefix, @@current_primer_filepath ) \
        end
    end
    
    
    
    # ==method: get
    #
    # a standard getter which primes the unprimed and recalls "expensive" facts from files
    # completely behind-the-scenes as directed by the resource (.res) files
    def get( k )
        
        
        if ! isset?( k )
            # prime if not yet primed
            primed?( k ) or _prime( k )
        end
        
        return _recallExpensive( k ) if expensive?( k )
        
        # if it's already set, return known answer
        if isset?( k )
            
            # _get the return value
            return_value = _get( k )
            
            # unset and unprime if destructOnGet?
            destroyOnGet?( k ) \
                and destroy! k
            
            return return_value
        end
        
    end
    
    # ==method: output
    #
    # an alias for get.  intended for use with primers that produce an output beyond their return value
    def output( k )
        return get( k )
    end
    
    # ==method: isset?
    #
    # returns true if sadie has a value for the key
    def isset?( key )
        return @shortterm.has_key?( key )
    end
    
    # ==method: setDestroyOnGet
    #
    #    key value will go away and key will be unprimed and unset after next get
    #
    #    NOTE: this doesn't make sense with keys that were set via setExpensive
    #          so it can be set, but nothing's going to happen differently
    def setDestroyOnGet( key, turnon=true )
        if ( turnon )
            @flag_destroyonget["#{key}"] = true
            return true
        end
        @flag_destroyonget.has_key?( key ) \
            and @flag_destroyonget.delete( key )
    end
    
    # ==method: destroy!
    #
    # remove the key from sadie
    def destroy! ( key )
        unset( key )
        primed?( key ) and unprime( key )
    end
    
    # ==method: destroyOnGet?
    #
    # returns true if the destructOnGet flag is set for the key
    def destroyOnGet?( key )
        ( @flag_destroyonget.has_key?( key ) && @flag_destroyonget["#{key}"] )
#         @flag_destroyonget.has_key?( key ) \
#             or return _newline( false )
#         @flag_destroyonget["#{key}"] \
#             and return _newline( true )
#         return _newline(false)
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
        
#         puts "setCheap( #{k}, #{v} )"
        
        # set it, mark not expensive and primed
        _set( k, v )
        _expensive( k, false )
        
        # if we've reset the primers dirpath, init the primers
        if k.eql?( "sadie.primers_dirpath" )
            initializePrimers
        end
        
       _primed( k, true )
        
        # if we've reset the primers dirpath, init the primers
        if k.eql?( "sadie.primers_dirpath" )
            Sadie::setCurrentSadieInstance( self )
        end
        
    end
    
    def cheap?( k )
        ! expensive? ( k )
    end
    
    # ==method: setExpensive
    #
    # the expensive setter.  key, value pairs stored via this method are not kept in memory
    # but are stored to file and recalled as needed
    def setExpensive(k,v)
#         puts "setting expensive, key: #{k}"
        expensive_filepath              = _computeExpensiveFilepath( k )
        serialized_value                = Marshal::dump( v )
        File.open(expensive_filepath, 'w') { |f|
            f.write( serialized_value )
        }
        _expensive( k, true )
        _primed( k, true )
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
    
    
    # ==method: save
    #
    # serialize to session file
    def save
        session_id = get("sadie.session_id")
        session_filepath = File.expand_path( "session."+session_id, get( "sadie.sessions_dirpath" ) )
        serialized_value                = Marshal::dump( [ @shortterm, @flag_primed, @flag_expensive ] )
        File.open(session_filepath, 'w') { |f|
            f.write( serialized_value )
        }
        return session_id
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
    

    
    private

    # ==method: unprime
    # unprimes k.  Note that this does not unset the value, so
    # get(key) will continue to return whatever it otherwise would have.
    # run unset as well to have the primer run again.
    def unprime( key )
        _primed( key, false )
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
    
    # direct access getter for shortterm memory
    def _get( key )
        value = @shortterm["#{key}"]
        return value
    end
    
    
    
    def primerPluginRegistered?( filename )
        
        @@primer_plugin_lookup.each do | plugin_array |
            re, path,accepts_block = plugin_array
            re.match( filename ) \
                and return true
        end
        return false;
    end
    
    def currentPrimerPluginAcceptsBlock( accepts )
        @@primer_plugin_accepts_block = accepts
    end
    
    def currentPrimerPluginAcceptsBlock?
        @@primer_plugin_accepts_block
    end
    
    def currentPrimerPluginPrimeOnInit( prime_on_init )
        @@primer_plugin_prime_on_init = prime_on_init
    end
    
    def currentPrimerPluginPrimeOnInit?
        @@primer_plugin_prime_on_init
    end
    
    def setMidPluginInit( filepath )
        @@mid_plugin_initialization     = true
        @@mid_plugin_filepath           = filepath
    end
    
    def unsetMidPluginInit
        @@mid_plugin_initialization     = false
    end
    
    def midPluginInit?
        @@mid_plugin_initialization
    end
    
    def regPluginMatch ( regexp, filepath, accepts_block, prime_on_init )
        @@primer_plugin_lookup.push( [ regexp, filepath, accepts_block, prime_on_init ] )
    end
    
    def primerPluginsInitialized?
        @@primer_plugins_initialized
    end
    
    # == initializePrimerPlugins
    #
    # register all the primer plugins
    #
    # called by initializePrimers so it's not necessary to call this separate from that
    def initializePrimerPlugins
        
        plugins_dirpath = get( "sadie.primer_plugins_dirpath" ) \
            or raise 'sadie.primer_plugins_dirpath not set'
        
        puts "Initializing primer plugins..."
        
        # load the plugins
        @plugins_dir_paths.each do | dirpath |
            Dir.foreach( dirpath ) do |filename|
                next if ! filename.match( /\.plugin\.rb$/ )
                
                filepath = File.expand_path( filename, dirpath )
                
                puts "initializing primer plugin with file: #{filename}"
                
                setMidPluginInit( filepath )
                load( filename )
                unsetMidPluginInit
            end
        end
        puts "...finished initializing primer plugins"
        @@primer_plugins_initialized = true
    end
    
    def setMidPrimerInit ( filepath )
        @@mid_primer_initialization     = true
        @@mid_primer_filepath           = filepath
    end
    
    def unsetMidPrimerInit
        @@mid_primer_initialization     = false
    end
    
    def midPrimerInit?
        @@mid_primer_initialization \
            and return true;
        return false;
    end

    
    
    def primersInitialized? ( toplevel_dirpath )
        @@flag_primed.has_key?( toplevel_dirpath ) \
            or return false;
        return @@flag_primed[toplevel_dirpath]
    end
    
    def initializePrimers
        
        Sadie::setCurrentSadieInstance( self )
        
        # make sure primer plugins have been initialized
        primerPluginsInitialized? \
            or initializePrimerPlugins
        
        
        primers_dirpath = get( "sadie.primers_dirpath" ) \
            or raise "sadie.primers_dirpath not set"

        return true if primersInitialized? primers_dirpath

        puts "Initializing primers..."
        initializePrimerDirectory( "", primers_dirpath )
        puts "...finished initializing primers."
        
        @@flag_primed[primers_dirpath] = true
    end
    
    def initializePrimerDirectory( key_prefix, current_dirpath )
        puts "initializing primer directory: #{current_dirpath}"
        Dir.foreach( current_dirpath ) do |filename|
            
           # skip the dit dirs
            next if filename.eql?(".") || filename.eql?("..")
            
            filepath = File.expand_path( filename, current_dirpath )
            
            if File.directory? filepath
                new_key_prefix = key_prefix + '.' + filename
                new_key_prefix = new_key_prefix.gsub(/^\.+/,"")
                initializePrimerDirectory( new_key_prefix, filepath )
            else
                initializePrimerFile( key_prefix, filepath )
            end
        end
    end
    
    def initializePrimerFile( key_prefix, filepath )
        
        
        basename = File.basename( filepath )
        if primerPluginRegistered? basename
            setCurrentPrimerFilepath filepath
            
            setCurrentPrimerKeyPrefix key_prefix
            
            basename = File.basename( filepath )
            initializePrimerWithPlugin( key_prefix, filepath )
            
            
        end
    end
    
    def initializePrimerWithPlugin( key_prefix, filepath )
        
        @@primer_plugin_lookup.each do | plugin_array |
           
           # we just need to match the basename
           filename = File.basename( filepath )
           
           regexp, plugin_filepath, accepts_block, prime_on_init = plugin_array
           
           if regexp.match( filename )
               
               setCurrentPrimerPluginFilepath( plugin_filepath )
               prime_on_init \
                    or setMidPrimerInit( filepath )
               
               plugin_filename = File.basename( plugin_filepath )
               
               load( plugin_filepath )
               
               prime_on_init \
                    or unsetMidPrimerInit
               
               
               return
           end
        end
    end
    
    def setCurrentPrimerPluginFilepath( filepath )
        @@current_primer_plugin_filepath = filepath
    end
    
    def getCurrentPrimerPluginFilepath
        @@current_primer_plugin_filepath
    end
    
    def setCurrentPrimerKeyPrefix ( prefix )
        @@current_primer_keyprefix = prefix
    end
    
    def getCurrentPrimerKeyPrefix 
        @@current_primer_keyprefix
    end
    
    def setCurrentPrimerFilepath ( filepath )
        @@current_primer_filepath = filepath
    end
    
    def getCurrentPrimerFilepath
        @@current_primer_filepath
    end
    
    def setCurrentPrimerRequestingKey( key )
        @@current_primer_requesting_key = key
    end
    
    def getCurrentPrimerRequestingKey
        @@current_primer_requesting_key
    end
    
    # ==memorizePrimerLocation
    #
    # internal, ignore the man behind the curtain
    def memorizePrimerLocation( filepath, plugin_filepath, primer_provides )
        
        # validate primer hash
        #primer_dirpath = @@mid_primer_toplevel_primer_dirpath
        primer_dirpath = _get("sadie.primers_dirpath")
        @@primer_hash.has_key?( primer_dirpath ) \
            or @@primer_hash["#{primer_dirpath}"] = Hash.new
        
        # interate over provides setting primer providers for each
        primer_provides.each do | key |
            setPrimerProvider( key, filepath, plugin_filepath, getCurrentPrimerKeyPrefix )
        end
    end
    
    
    # ==setPrimerProvider
    #
    # internal, ignore the man behind the curtain
    def setPrimerProvider( primer_name, primer_filepath, primer_plugin_filepath, key_prefix )
        
        primer_dirpath = _get( "sadie.primers_dirpath" )
        @@primer_hash.has_key?( primer_dirpath ) \
            or @@primer_hash[primer_dirpath] = Hash.new
        
        @@primer_hash["#{primer_dirpath}"]["#{primer_name}"] = [ primer_filepath, primer_plugin_filepath, key_prefix ]
        
    end
    
    def getPrimerProvider( key )
        
        # fetch primers dirpath and validate the primer hash
        primer_dirpath = _get( "sadie.primers_dirpath" )
        @@primer_hash.has_key?( primer_dirpath ) \
            or @@primer_hash[primer_dirpath] = Hash.new
        
        primers = @@primer_hash[primer_dirpath]
        primers.has_key?( key ) \
            or return nil             # primer not defined
        
        return primers[key]
    end
    
    
    
    def _primed ( k, is_primed )
        defined? k \
            or raise '_primed> reqd parameter, k, was undefined'
        k.is_a?( String ) \
            or raise '_primed> reqd parameter, k, was non-string'
        if ( is_primed )
            @flag_primed[k] = true
            return true
        end
        @flag_primed.has_key?( k ) \
            or return true
        @flag_primed.delete( k )
    end

    def _prime ( k )
        
        if provider  = getPrimerProvider( k )
            primer_filepath, plugin_filepath, key_prefix = provider
        
            setCurrentPrimerFilepath(primer_filepath)
            setCurrentPrimerKeyPrefix( key_prefix )
            Sadie::setCurrentSadieInstance( self )
            
#             puts "_prime( #{k} ) loading #{provider}"
            
            load plugin_filepath
        end
        
    end
    

    def _newline( rval=true )
        return rval
    end
    
    # ==method: unset
    # unsets the value of k.  Note that this does not unprime, so
    # get(key) will simply return nil. Run with unprime to have the
    # primer run again
    def unset( key )
        _unset( key )
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
    
    def _expensive( k, isexpensive )
        if isexpensive
            @flag_expensive["#{k}"]    = true
            return
        end
        @flag_expensive.delete( k )
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
    
    
    # init given path to session file
    def _initializeWithSessionFilePath( session_filepath )
        
        puts "session_filepath: #{session_filepath}"
        
        defined?( session_filepath ) \
            or raise "session_filepath was undefined"
        
        /^\s*$/.match("#{session_filepath}") \
            and raise "session_filepath was empty string"
        
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
        session_filepath = File.expand_path( "session."+session_id, _get( "sadie.sessions_dirpath" ) )
        _initializeWithSessionFilePath( session_filepath )
    end
        
    # gen new session id
    def _generateNewSessionId
        begin
            value = ""
            24.times{value  << (65 + rand(25)).chr}
        end while File.exist?(File.expand_path("session."+value, get( "sadie.sessions_dirpath" ) ) )
        return value
    end
    
    # ==method: checkInstanceSanity
    #
    # verifies that needed instance variables are defined
    def _checkInstanceSanity
        defined? @shortterm \
            or @shortterm               = Hash.new
        defined? @flag_expensive \
            or @flag_expensive          = Hash.new
        defined? @flag_destroyonget \
            or @flag_destroyonget       = Hash.new
        defined? @flag_primed \
            or @flag_primed             = Hash.new
        
    end
    
    # ==method: checkClassSanity
    #
    # verifies that needed class variables are defined
    def _checkClassSanity
        defined? @@flag_primed \
                or @@flag_primed        = Hash.new
        
        # init primer plugin vars
        if ( ! defined? @@primer_plugin_lookup )
            @@mid_plugin_initialization     = false
            @@primer_plugin_lookup          = Array.new
            @@primer_plugins_initialized    = false
        end
        
        # init primer vars
        defined? @@primer_hash \
            or @@primer_hash            = Hash.new
         defined? @flag_primed \
            or @flag_primed             = Hash.new
        if ! defined? @@mid_primer_initialization
            @@mid_primer_initialization = false
            @@mid_primer_filepath       = nil
        end
        
    end
    
    
end

require "sadie/version"
require "sadie/defaults"

