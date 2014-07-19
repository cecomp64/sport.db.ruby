# encoding: utf-8

### note: some utils moved to worldbdb/utils for reuse


####
## move to folder matcher(s)/finder(s)
#  -- rename to FixtureFinder or FixtureFinders
#  or just GeneralFinder
#   TeamFinder etc.  ???


module SportDb
  module FixtureHelpers


  def cut_off_end_of_line_comment!( line )
    #  cut off (that is, remove) optional end of line comment starting w/ #
    
    line.sub!( /#.*$/ ) do |_|
      logger.debug "   cutting off end of line comment - >>#{$&}<<"
      ''
    end
    
    # NB: line = line.sub  will NOT work - thus, lets use line.sub!
  end

  def find_leading_pos!( line )
    # extract optional game pos from line
    # and return it
    # NB: side effect - removes pos from line string

    # e.g.  (1)   - must start line 
    regex = /^[ \t]*\((\d{1,3})\)[ \t]+/
    if line =~ regex
      logger.debug "   pos: >#{$1}<"

      line.sub!( regex, '[POS] ' ) # NB: add trailing space
      return $1.to_i
    else
      return nil
    end
  end

  def find_game_pos!( line )
    ## fix: add depreciation warning - remove - use find_leading_pos!
    find_leading_pos!( line )
  end

  # Parse out stats format
  # $$ statKey: value, statKey: value
  # Assumes stats apply to a person or a game
  # Create a stats object if one does not exist for this
  # person/game.  Update the corresponding statistic
  #
  # Returns true if this line is a stats line
  def parse_stats (line, event, person=nil, game=nil)

    # For simplicity, have stat lines start with $$
    if (not (line =~ /^\$\$/))
      return false
    end

    if (person == nil and game == nil)
      logger.error " !!!!!! No person or game to match stats with line: #{line}"
      # Return true to skip the line
      return true
    end

    # Parse out components
    line.sub!("$$","").strip!
    stats_l = line.split(",")

    logger.debug "   stats_l: #{stats_l}"

    stats_l.each do |stat_s|
      logger.debug "   stat_s: #{stat_s}"
      components_l = stat_s.split(":")
      if (components_l[1] == nil)
        logger.error " !!!!!! Malformed stats line: #{stat_s}"
        next
      end

      # Stat values
      stat_key = components_l[0]

      # Find or create a stat
      stat = Model::Stat.find_by_key(stat_key)
      if (stat == nil)
        stat = Model::Stat.create(key: stat_key, title: stat_key)
      end

      logger.debug "   Using stat: #{stat.title}"

      # Find or create stat_data
      stat_data = nil
      stat_data_attr = {
        value: components_l[1],
        event_id: event.id,
        stat_id: stat.id
      }

      # Could be a person stat, team stat, game stat, or event stat
      # TBD: Support team stat and event-only stat properly
      if (person != nil)
        stat_data_attr[:person_id] = person.id
        stat_data = Model::StatData.find_by_event_id_and_person_id_and_stat_id(event.id, person.id, stat.id)
      else # game
        stat_data_attr[:game_id] = game.id
        stat_data = Model::StatData.find_by_event_id_and_game_id_and_stat_id(event.id, game.id, stat.id)
      end

      # Create or update stat
      if (stat_data == nil)
        stat_data = Model::StatData.create(stat_data_attr)
      else
        stat_data = Model::StatData.update_attributes!(stat_data_attr)
      end

      logger.debug "   Saved stat_data: #{stat_data.to_s}"

    end # each stat

    return true
  end

  end # module FixtureHelpers
end # module SportDb
