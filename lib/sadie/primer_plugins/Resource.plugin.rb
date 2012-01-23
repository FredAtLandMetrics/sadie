# requires dbconx plugin to be installed as well

require 'sadie'

Sadie::registerPrimerPlugin( { "match" => /\.res$/,
                                "accepts-block" => true } ) do |sadie, primer_file_filepath, block|
    # load the res file
    Sadie::setMidPrimerInit( primer_file_filepath )
    load( primer_file_filepath )
    Sadie::unsetMidPrimerInit
end
