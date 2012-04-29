# this requires the gem: ini
require 'rubygems'
require "bundler/setup"
require 'bundler'
Bundler.require(:default)
require 'sadie/defaults'
require 'sadie/version'
require 'erb'

# ==Description: Sadie
# Sadie is a data framework intended to ease the pain of constructing, accessing, and 
# managing the resources required by large stores of inter-related data. It supports
# sessions, lazy, on-demand, one-time evaluation and file-based storage/retrieval
# operations for resource-heavy data.
# 
# New types of data primers can be added by calling addPrimerPluginsDirPath with a
# directory containing plugin definitions
#

def S( key )
    instance = Sadie::getCurrentSadieInstance
    return instance.get( key )
end

class Sadie
    
    
    BEFORE      = 1
    AFTER       = 2
    EACH        = 3
    
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
        @current_sadie_instance = instance
    end
    
    # ==method: Sadie::getCurrentSadieInstance
    #
    # called by plugin handlers to get access to the current Sadie instance
    def self.getCurrentSadieInstance
        @current_sadie_instance
    end    
    
    # ==method: Sadie::Prime
    #
    # called by the .res files to register the keys the .res will prime for
    # 
    # accepts as an argument a hash and a block.  The hash must include the key:
    # 'provides' and it must define an array
    # of keys that the calling resource (.res) file will have provided after the block is
    # evaluated
    def self.prime ( primer_definition, &block )
        current_sadie_instance = Sadie::getCurrentSadieInstance
        current_sadie_instance.prime( primer_definition, &block )
    end

    # ==method: Sadie::eacher
    #
    # called by eacher files to hook into priming operations and calls to set method
    def self.eacher( eacher_params, &block )
        current_sadie_instance = Sadie::getCurrentSadieInstance
        current_sadie_instance.eacher( eacher_params, &block )
    end
    
    # ==method: Sadie::eacherFrame
    #
    # eacherFrame is called by get and set methods and is available to primer plugins
    # as well. when eacher primer files call eacher, they are registering code to
    # be run either BEFORE or AFTER the key/value store is set.  Note that the BEFORE
    # eacherFrame runs just before priming when a primer exists and just before set
    # for keys set without primers.  EACH eacherFrames are called as the data is being
    # assembled, if such a thing makes sense.  The included SQLQueryTo2DArray plugin
    # tries to call any eacherFrame with an EACH occurAt parameter with each row and
    # the registering an EACH eacher might make sense for any number of incrementally
    # built data types
    # 
    def self.eacherFrame( sadiekey, occur_at, param=nil )
        current_sadie_instance = Sadie::getCurrentSadieInstance
        current_sadie_instance.eacherFrame( sadiekey, occur_at, param )
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
                elsif matches = line.match(/^\s*([^\s\=]+)\s*\=\s*([^\s]+.*)\s*$/)
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
    
    # ==method: Sadie::templatedFileToString
    #
    # utility class method.  accepts a filepath.  digests a template and returns
    # a string containing processed template output
    #
    def self.templatedFileToString( filepath, binding=nil )
        
        template = ERB.new File.new(filepath).read
        current_sadie_instance = Sadie::getCurrentSadieInstance
        if defined? binding
            template.result binding 
        else
            template.result self
        end
        
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
        
        Sadie::setCurrentSadieInstance( self )
        
        # internalize defaults to shortterm
        DEFAULTS.each do |key, value|
                _set( key, value )
        end
        
        # iterate over constructor args, but do primers_dirpath last since it
        # causes a call to initializePrimers
        options.each do |key, value|
                set( key, value )
        end
                
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
        
        # add the default sadie plugins dir
        plugins_dirpath = "lib/sadie/primer_plugins"   # for dev
        if ! File.exists? plugins_dirpath
            plugins_dirpath = File.join(
                ENV['GEM_HOME'],
                "gems/sadie-#{Sadie::VERSION}",
                "lib/sadie/primer_plugins"
            )
            
            if ! File.exists? plugins_dirpath
                plugins_dirpath = File.expand_path "../sadie/lib/sadie/primer_plugins"
            end
            
        end        
        addPrimerPluginsDirPath plugins_dirpath
        
    end
    
    # ==method: setDebugLevel
    #
    # from 0 to 10 with 0 being no debugging messages and 10 being all debugging messages
    # 
    def setDebugLevel( lvl )
        lvl > 10 and lvl = 10
        lvl < 0 and lvl = 0
        @debug_level  = lvl.to_i
    end
    
    # ==method: getDebugLevel
    #
    # return current debug level (default is 10)
    # 
    def getDebugLevel
        defined? @debug_level or @debug_level = 10
        @debug_level
    end
    
    # ==method: getDebugLevel
    #
    # will print a debugging message if the current debug level is greater than
    # or equal to lvl
    # 
    def debug!( lvl, msg )
        defined? @debug_level or @debug_level = 10
        (lvl <= @debug_level) and puts "SADIE(#{lvl}): #{msg}"
    end
    
    # ==method: eacher
    #
    # ( usually this will be called by the class method...it looks better )
    #
    # see class method eacher for an explanation
    #
    def eacher( params, &block )
        filepath        = getCurrentPrimerFilepath
        key_prefix      = getCurrentPrimerKeyPrefix
        occur_at        = params[:when]
        
        # gen sadie key
        basefilename    = filepath.gsub(/^.*\//,"")
        sadiekey        = key_prefix + "." + basefilename.gsub(/\.each(?:\..*)*$/,"")
        sadiekey        = sadiekey.gsub( /^\.+/,"" )
        if params.has_key? "sadiekey"
            sadiekey    = params["sadiekey"]
        end
        
        if midEacherInit?
            
            debug! 10, "in mid eacher init (#{sadiekey})"
            
            memorizeEacherFileLocation( sadiekey, filepath )
            
            if params.has_key? :provides
                
                # make sure we're passing an array
                provide_array = params[:provides]
                provide_array.respond_to? "each" or provide_array = [provide_array]
                
                # tell sadie that the sadiekey primer also provides everything in the provide array
                setEachersProvidedByPrimer( sadiekey, provide_array )
                
            end            
            
        elsif whichEacherFrame == occur_at
            if block.arity == 0
                yield self
            else
                yield self, getEacherParam
            end
        end
    end
    
    # ==method: eacherFrame
    #
    # ( usually this will be called by the class method...it looks better )
    #
    # see class method eacherFrame for an explanation
    #    
    def eacherFrame( sadiekey, occur_at, param=nil )
        
        debug! 8, "eacherFrame(#{occur_at}): #{sadiekey}"
        
        key = sadiekey
#         if defined? @eacher_frame_redirect
#             if @eacher_frame_redirect.has_key? key
#                 key = @eacher_frame_redirect[key]
#             end
#         end
        
        setEacherFrame( occur_at )
        defined? param and setEacherParam( param )
        if filepaths = eacherFilepaths( key )
            filepaths.each do |filepath|
                debug! 10, "each frame loading: #{filepath} for key: #{key}"
                load filepath
            end
        end
        unsetEacherParam
        unsetEacherFrame
    end
    
    
    # ==method: addPrimerPluginsDirPath
    #
    # addPrimerPluginsDirPath adds a directory which will be scanned for plugins to
    # register just before initializePrimers looks for primers to initialize
    #    
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
        
        @primer_plugins_initialized = nil
        return self
    end
    
    # ==method: prime
    #
    # ( usually this will be called by the class method...it looks better )
    #
    # see class method prime for an explanation
    #    
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
            memorizePrimerLocation( @mid_primer_filepath, getCurrentPrimerPluginFilepath, primer_definition["provides"] )
        else
            
            # run code block with the current sadie instance
            block.call( self )
            
            # loop thru all primer provides, ensuring each primed
            current_primer_filepath = getCurrentPrimerFilepath
            primer_definition["provides"].each do | key |
                
                # skip blank lines
                next if key.match /^\s*$/
                
                # key primed or raise error
                primed? key \
                    or raise "primer definition file: #{current_primer_filepath} was supposed to define #{key}, but did not"
            end
        end
        
    end

    # ==method: registerPrimerPlugin
    #
    # ( usually this will be called by the class method...it looks better )
    #
    # see class method registerPrimerPlugin for an explanation
    #    
    def registerPrimerPlugin ( arghash, &block )
        
        # if mid plugin init is set, we're registering the plugin
        # init mode, just store arghash info
        accepts_block = arghash.has_key?( "accepts-block" ) && arghash["accepts-block"] ? true : false
        prime_on_init = arghash.has_key?( "prime-on-init" ) && arghash["prime-on-init"] ? true : false
        
        # if mid plugin init, register the plugin params with the match
        if midPluginInit?
            
            regPluginMatch( arghash["match"], @mid_plugin_filepath, accepts_block, prime_on_init )
            
        # midplugininit returned false, we're actually in the process of either initializing
        # a primer or actually priming
        else
            yield self, getCurrentPrimerKeyPrefix, getCurrentPrimerFilepath
        end
    end
    
    
    
    # ==method: get
    #
    # a standard getter which primes the unprimed and recalls "expensive" facts from files
    # completely behind-the-scenes as directed by the resource (.res) files
    def get( k )
        
        debug! 10, "get(#{k})"
        
        defined? @eacher_frame_redirect or @eacher_frame_redirect = Hash.new
        
        if ! isset?( k )
            debug! 10, "#{k} is not set"
            if isEacherKey?( k )
                debug! 10, "sadiekey: #[k} is eacher, fetching: #{@eacher_frame_redirect[k]}"
                get @eacher_frame_redirect[k]
            
            elsif primeable?( k )
                
                debug! 10, "calling eacher from get method for #{k}"
                setUnbalancedEacher k
                Sadie::eacherFrame( k, BEFORE )
                
                # prime if not yet primed
                primed?( k ) or _prime( k )
            end
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
        
        debug! 9,  "setting cheap: #{k}"
        Sadie::eacherFrame( k, BEFORE ) if ! eacherUnbalanced?( k )
                setUnbalancedEacher k
        
        if getDebugLevel == 10
            debug! 10, "dumping value:"
            pp v
        end
        
        # set it, mark not expensive and primed
        _set( k, v )
        _expensive( k, false )
        _primed( k, true )
        
        Sadie::eacherFrame( k, AFTER, v )
        clearUnbalancedEacher k
        
    end
    
    # ==method: setExpensive
    #
    # the expensive setter.  key, value pairs stored via this method are not kept in memory
    # but are stored to file and recalled as needed
    def setExpensive(k,v)
        
        debug! 9,  "setting expensive: #{k}"
        Sadie::eacherFrame( k, BEFORE ) if ! eacherUnbalanced?( k )
                         setUnbalancedEacher k

        
        expensive_filepath              = _computeExpensiveFilepath( k )
        serialized_value                = Marshal::dump( v )
        
        File.exist? File.dirname( expensive_filepath ) \
            or Dir.mkdir File.dirname( expensive_filepath )
        
        File.open(expensive_filepath, 'w') { |f|
            f.write( serialized_value )
        }
        _expensive( k, true )
        _primed( k, true )
        
        Sadie::eacherFrame( k, AFTER, v )
        clearUnbalancedEacher k
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
    
    # ==method: initializePrimers
    #
    # call this method only after registering all the plugin directories and setting the
    # appropriate session and primer directory paths.  after this is called, the key/val
    # pairs will be available via get
    #
    def initializePrimers
        
        Sadie::setCurrentSadieInstance( self )
        
        # make sure primer plugins have been initialized
        primerPluginsInitialized? \
            or initializePrimerPlugins
        
        eachersInitialized? \
            or initializeEachers
        
        primers_dirpath = get( "sadie.primers_dirpath" ) \
            or raise "sadie.primers_dirpath not set"

        return true if primersInitialized? primers_dirpath

        debug! 1, "Initializing primers..."
        initializePrimerDirectory( "", primers_dirpath )
        debug! 1, "...finished initializing primers."
        
        @flag_primed[primers_dirpath] = true
    end
    

# ------------------------------------------------------------------------------------------------    
# ------------------------------------------------------------------------------------------------    

    private

    def setUnbalancedEacher( k )
        debug! 10, "setting eacher unbalanced: #{k}"
        defined? @eacher_unbalanced or @eacher_unbalanced = Hash.new
        @eacher_unbalanced[k] = true
    end
    
    def clearUnbalancedEacher( k )
         debug! 10, "clearing eacher unbalanced: #{k}"
       @eacher_unbalanced[k] = false if defined? @eacher_unbalanced
    end
    
    def eacherUnbalanced?( k )
        return false if ! defined? @eacher_unbalanced
        return false if ! @eacher_unbalanced.has_key?( k )
        return @eacher_unbalanced[k]
    end
    
    def cheap?( k )
        ! expensive? ( k )
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
    
   
    # == initialize eachers
    #
    # register all the eachers
    #
    # called by initializePrimers so it's not necessary to call this separate from that
    def initializeEachers
        
        primers_dirpath = get( "sadie.primers_dirpath" ) \
            or raise "sadie.primers_dirpath not set"

        puts "Initializing eachers..."
        setEacherInit
        initializeEacherDirectory( "", primers_dirpath )
        clearEacherInit
        puts "...finished initializing eachers."
        
        
        @eachers_initialized = true
    end
    
    def initializeEacherDirectory( key_prefix, current_dirpath )
        
        debug! 3, "initializing eacher directory: #{current_dirpath}"
        Dir.foreach( current_dirpath ) do |filename|
            
           # skip the dit dirs
            next if filename.eql?(".") || filename.eql?("..") || filename =~ /\~$/
            
            
            filepath = File.expand_path( filename, current_dirpath )
            
            if File.directory? filepath
                new_key_prefix = key_prefix + '.' + filename
                new_key_prefix = new_key_prefix.gsub(/^\.+/,"")
                initializeEacherDirectory( new_key_prefix, filepath )
            else
                if filename =~ /\.each(?:\..*)*$/
                    initializeEacherFile( key_prefix, filepath )
                end
            end
        end
    end
    
    def initializeEacherFile( key_prefix, filepath )
        debug! 8, "initializing eacher file (#{key_prefix}): #{filepath}"
        setCurrentPrimerFilepath filepath
        setCurrentPrimerKeyPrefix key_prefix
        load filepath
    end
        
    def eachersInitialized?
        defined? @eachers_initialized or return false
        @eachers_initialized and return true
        return false
    end
    
    
    
    
    def whichEacherFrame
        @eacher_frame
    end
    
    def setEacherFrame( f )
        @eacher_frame = f
    end
    
    def unsetEacherFrame
        @eacher_frame = nil
    end
    
    def setEacherParam( p )
        @eacher_param = p
    end
    
    def unsetEacherParam
        @eacher_param = nil
    end
    
    def getEacherParam
        @eacher_param
    end
    

    def isEacherKey?( key )
        
        defined? @eacher_frame_redirect or return false
        @eacher_frame_redirect.has_key? key or return false
        return true
    end
    
    def getEacherDependency( key )
        defined? @eacher_frame_redirect or return nil
        @eacher_frame_redirect.has_key? key or return nil
        @eacher_frame_redirect[key]
    end
    
    def getEachersProvidedByPrimer( sadiekey )
        defined? @eachers_provided or return nil
        @eachers_provided.has_key? sadiekey or return nil
        @eachers_provided[sadiekey]
    end
    
    
    
    def eacherFilepaths( sadiekey )
        defined? @eacher_filepaths or return nil
        @eacher_filepaths.has_key? sadiekey or return nil
        @eacher_filepaths[sadiekey]
    end
    
    def midEacherInit?
        defined? @eacher_init or return false
        @eacher_init or return false
        true
    end
    
    def setEacherInit
        @eacher_init = true
    end
    
    def clearEacherInit
        @eacher_init = nil
    end

    
    def setEachersProvidedByPrimer( sadiekey, providers )
        
        # record reverse map for use by eacherFrame
        defined? @eacher_frame_redirect \
            or @eacher_frame_redirect = Hash.new
        providers.each do |provider|
            debug! 10, "setting provider reverse map for #{provider} to #{sadiekey}"
            @eacher_frame_redirect[provider] = sadiekey
        end
        
        defined? @eachers_provided or @eachers_provided = Hash.new
        if @eachers_provided.has_key? sadiekey
            @eachers_provided[sadiekey] = @eachers_provided[sadiekey].concat( providers )
        else
            @eachers_provided[sadiekey] = providers
        end
    end
    
    
    
    def memorizeEacherFileLocation( sadiekey, filepath )
        debug! 10, "memorizing eacher file location: #{filepath} for #{sadiekey}"
        # store the file path
        defined? @eacher_filepaths or @eacher_filepaths = Hash.new
        if ! @eacher_filepaths.has_key? sadiekey
            @eacher_filepaths[sadiekey] = [filepath]
        elsif ! @eacher_filepaths[sadiekey].include? filepath
            @eacher_filepaths[sadiekey].push filepath
        end
    end
    
    
    
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
        
        isset?( k ) and return true
        
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
        
        @primer_plugin_lookup.each do | plugin_array |
            re, path,accepts_block = plugin_array
            re.match( filename ) \
                and return true
        end
        return false;
    end
    
    def currentPrimerPluginAcceptsBlock( accepts )
        @primer_plugin_accepts_block = accepts
    end
    
    def currentPrimerPluginAcceptsBlock?
        @primer_plugin_accepts_block
    end
    
    def currentPrimerPluginPrimeOnInit( prime_on_init )
        @primer_plugin_prime_on_init = prime_on_init
    end
    
    def currentPrimerPluginPrimeOnInit?
        @primer_plugin_prime_on_init
    end
    
    def setMidPluginInit( filepath )
        @mid_plugin_initialization     = true
        @mid_plugin_filepath           = filepath
    end
    
    def unsetMidPluginInit
        @mid_plugin_initialization     = false
    end
    
    def midPluginInit?
        @mid_plugin_initialization
    end
    
    def regPluginMatch ( regexp, filepath, accepts_block, prime_on_init )
        @primer_plugin_lookup.push( [ regexp, filepath, accepts_block, prime_on_init ] )
    end
    
    def primerPluginsInitialized?
        @primer_plugins_initialized
    end
    
    # == initializePrimerPlugins
    #
    # register all the primer plugins
    #
    # called by initializePrimers so it's not necessary to call this separate from that
    def initializePrimerPlugins
        
        defined? @plugins_dir_paths \
            or raise 'plugins_dir_paths not set'
        
        debug! 1, "Initializing primer plugins..."
        
        # load the plugins
        @plugins_dir_paths.each do | dirpath |
            Dir.foreach( dirpath ) do |filename|
                next if ! filename.match( /\.plugin\.rb$/ )
                
                filepath = File.expand_path( filename, dirpath )
                
                debug! 2, "initializing primer plugin with file: #{filename}"
                
                setMidPluginInit( filepath )
                load( filename )
                unsetMidPluginInit
            end
        end
        debug! 1, "...finished initializing primer plugins"
        @primer_plugins_initialized = true
    end
    
    def setMidPrimerInit ( filepath )
        @mid_primer_initialization     = true
        @mid_primer_filepath           = filepath
    end
    
    def unsetMidPrimerInit
        @mid_primer_initialization     = false
    end
    
    def midPrimerInit?
        @mid_primer_initialization \
            and return true;
        return false;
    end

    
    
    def primersInitialized? ( toplevel_dirpath )
        @flag_primed.has_key?( toplevel_dirpath ) \
            or return false;
        return @flag_primed[toplevel_dirpath]
    end
    
    def initializePrimerDirectory( key_prefix, current_dirpath )
        puts "initializing primer directory: #{current_dirpath}"
        Dir.foreach( current_dirpath ) do |filename|
            
           # skip the dit dirs
            next if filename.eql?(".") || filename.eql?("..") || filename =~ /\~$/
            
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
        
        debug! 9, "initializing primer file #{File.basename(filepath)} with plugin"
        
        @primer_plugin_lookup.each do | plugin_array |
           
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
        @current_primer_plugin_filepath = filepath
    end
    
    def getCurrentPrimerPluginFilepath
        @current_primer_plugin_filepath
    end
    
    def setCurrentPrimerKeyPrefix ( prefix )
        @current_primer_keyprefix = prefix
    end
    
    def getCurrentPrimerKeyPrefix 
        @current_primer_keyprefix
    end
    
    def setCurrentPrimerFilepath ( filepath )
        @current_primer_filepath = filepath
    end
    
    def getCurrentPrimerFilepath
        @current_primer_filepath
    end
    
    def setCurrentPrimerRequestingKey( key )
        @current_primer_requesting_key = key
    end
    
    def getCurrentPrimerRequestingKey
        @current_primer_requesting_key
    end
    
    # ==memorizePrimerLocation
    #
    # internal, ignore the man behind the curtain
    def memorizePrimerLocation( filepath, plugin_filepath, primer_provides )
        
        # validate primer hash
        #primer_dirpath = @mid_primer_toplevel_primer_dirpath
        primer_dirpath = _get("sadie.primers_dirpath")
        @primer_hash.has_key?( primer_dirpath ) \
            or @primer_hash["#{primer_dirpath}"] = Hash.new
        
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
        @primer_hash.has_key?( primer_dirpath ) \
            or @primer_hash[primer_dirpath] = Hash.new
        
        @primer_hash["#{primer_dirpath}"]["#{primer_name}"] = [ primer_filepath, primer_plugin_filepath, key_prefix ]
        
    end
    
    def primeable?( key )
        p = getPrimerProvider( key )
        return nil if ! defined? (p )
        return nil if p == nil
        return true
    end
    
    def getPrimerProvider( key )
        
        # fetch primers dirpath and validate the primer hash
        primer_dirpath = _get( "sadie.primers_dirpath" )
        @primer_hash.has_key?( primer_dirpath ) \
            or @primer_hash[primer_dirpath] = Hash.new
        
        primers = @primer_hash[primer_dirpath]
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
        
        debug! 10, "priming: #{k}"
        
        if isEacherKey? k
            get( getEacherDependency( k ) )
        else
        
            #Sadie::eacherFrame( k, BEFORE )
            if provider  = getPrimerProvider( k )
                primer_filepath, plugin_filepath, key_prefix = provider
            
                currfilepath = getCurrentPrimerFilepath
                
                setCurrentPrimerFilepath(primer_filepath)
                setCurrentPrimerKeyPrefix( key_prefix )
                Sadie::setCurrentSadieInstance( self )
                
                load plugin_filepath
                
                if defined? currfilepath
                    setCurrentPrimerFilepath currfilepath
                end
            end
            #Sadie::eacherFrame( k, AFTER )
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
        defined? @flag_primed \
                or @flag_primed        = Hash.new
        
        # init primer plugin vars
        if ( ! defined? @primer_plugin_lookup )
            @mid_plugin_initialization     = false
            @primer_plugin_lookup          = Array.new
            @primer_plugins_initialized    = false
        end
        
        # init primer vars
        defined? @primer_hash \
            or @primer_hash            = Hash.new
         defined? @flag_primed \
            or @flag_primed             = Hash.new
        if ! defined? @mid_primer_initialization
            @mid_primer_initialization = false
            @mid_primer_filepath       = nil
        end
        
    end
    
    
end

require "sadie/version"
require "sadie/defaults"

