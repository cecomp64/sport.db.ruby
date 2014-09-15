# encoding: UTF-8

module SportDb


class EventReader

  include LogUtils::Logging

## make models available by default with namespace
#  e.g. lets you use Usage instead of Model::Usage
  include Models


  attr_reader :include_path
  attr_reader :event           # returns event record; call read first

  def initialize( include_path, opts = {} )
    @include_path = include_path

    @name     = nil
    @event    = nil
    @fixtures = []
  end


  def fixtures
    ## note: needs to call read first (to set @name, @fixtures, etc.)

    if @fixtures.empty?
      ## logger.warn "no fixtures found for event - >#{name}<; assume fixture name is the same as event"
      fixtures_with_path = [ @name ]
    else
      ## add path to fixtures (use path from event e.g)
      #  - bl    + at-austria!/2012_13/bl  -> at-austria!/2012_13/bl
      #  - bl_ii + at-austria!/2012_13/bl  -> at-austria!/2012_13/bl_ii

      dir = File.dirname( @name ) # use dir for fixtures

      fixtures_with_path = @fixtures.map do |fx|
        fx_new = "#{dir}/#{fx}"   # add path upfront
        logger.debug "fx: #{fx_new} | >#{fx}< + >#{dir}<"
        fx_new
      end
    end

    fixtures_with_path
  end



  def read( name, more_attribs={} )
    @fixtures = []    # reset cached fixtures
    @event    = nil   # reset cached event rec
    @name     = name  # keep name (needed for fixtures attrib getter)

####
## fix!!!!!
##   use Event.create_or_update_from_hash or similar
##   use Event.create_or_update_from_hash_reader?? or similar
#   move parsing code to model

    reader = HashReaderV2.new( name, include_path )

    event_attribs = {}
    
    ## set default sources to basename by convention
    #  e.g  2013_14/bl  => bl
    #  etc.
    # use fixtures/sources: to override default

    event_attribs[ 'sources' ] = File.basename( name )
    event_attribs[ 'config'  ] = File.basename( name )  # name a of .yml file

    reader.each_typed do |key, value|

      ## puts "processing event attrib >>#{key}<< >>#{value}<<..."

      if key == 'league'
        league = League.find_by_key( value.to_s.strip )

        ## check if it exists
        if league.present?
          event_attribs['league_id'] = league.id
        else
          logger.error "league with key >>#{value.to_s.strip}<< missing"
          exit 1
        end
       
      elsif key == 'season'
        season = Season.find_by_key( value.to_s.strip )

        ## check if it exists
        if season.present?
          event_attribs['season_id'] = season.id
        else
          logger.error "season with key >>#{value.to_s.strip}<< missing"
          exit 1
        end
        
      elsif key == 'start_at' || key == 'begin_at'
        
        if value.is_a?(DateTime) || value.is_a?(Date)
          start_at = value
        else # assume it's a string
          start_at = DateTime.strptime( value.to_s.strip, '%Y-%m-%d' )
        end
        
        event_attribs['start_at'] = start_at

      elsif key == 'end_at' || key == 'stop_at'
        
        if value.is_a?(DateTime) || value.is_a?(Date)
          end_at = value
        else # assume it's a string
          end_at = DateTime.strptime( value.to_s.strip, '%Y-%m-%d' )
        end
        
        event_attribs['end_at'] = end_at

      elsif key == 'grounds' || key == 'stadiums' || key == 'venues'
        ## assume grounds value is an array
        
        ##
        ## note: for now we allow invalid ground keys
        ##  will skip keys not found
        
        ground_ids = []
        value.each do |item|
          ground_key = item.to_s.strip
          ground = Ground.find_by_key( ground_key )
          if ground.nil?
            puts "[warn] ground/stadium w/ key >#{ground_key}< not found; skipping ground"
          else
            ground_ids << ground.id
          end
        end

        event_attribs['ground_ids'] = ground_ids
      elsif key == 'teams'
        ## assume teams value is an array
        
        team_ids = []
        value.each do |item|
          team_key = item.to_s.strip
          puts "team_key: #{team_key}"
          team = Team.find_by_key!( team_key )
          team_ids << team.id
        end
        
        event_attribs['team_ids'] = team_ids
        
      elsif key == 'team3'
        ## for now always assume false  # todo: fix - use value and convert to boolean if not boolean
        event_attribs['team3'] = false

      elsif key == 'fixtures' || key == 'sources'
        ### todo: check for mulitiple fixtures/sources ?? allow disallow?? why? why not?
        if value.kind_of?(Array)
          event_attribs['sources'] = value.join(',')
          @fixtures += value
        else # assume plain (single fixture) string
          event_attribs['sources'] = value.to_s
          @fixtures << value.to_s
        end
      else
        ## todo: add a source location struct to_s or similar (file, line, col)
        logger.error "unknown event attrib #{key}; skipping attrib"
      end

    end # each key,value

    league_id = event_attribs['league_id']
    season_id = event_attribs['season_id']

    logger.debug "find event - league_id: #{league_id}, season_id: #{season_id}"

    event = Event.find_by_league_id_and_season_id( league_id, season_id )

    ## check if it exists
    if event.present?
      logger.debug "*** update event #{event.id}-#{event.key}:"
    else
      logger.debug "*** create event:"
      event = Event.new
    end
    
    logger.debug event_attribs.to_json

    event.update_attributes!( event_attribs )
    
    # keep a cached reference for later use
    @event = event
  end  # method read


end # class EventReader
end # module SportDb
