# encoding: utf-8

###
# NB: for local testing run like:
#
# 1.9.x: ruby -Ilib lib/sportdb.rb

# core and stlibs  (note: get included via worlddb gem; see worlddb gem/lib)


# rubygems  / 3rd party libs

require 'active_record'
require 'activerecord/utils' # check - if dependency on logutils? or props? etc let others go first
# fix: move activerecord/utils to world db - no need to require here again

require 'worlddb'
require 'persondb'

require 'logutils/db'   # NB: explict require required for LogDb (NOT automatic)
# fix: move to world db  -- no need to require here


require 'fetcher'   # for fetching/downloading fixtures via HTTP/HTTPS etc.

# our own code

require 'sportdb/version'    # let version always go first

require 'sportdb/patterns'
require 'sportdb/models/forward'
require 'sportdb/models/world/city'
require 'sportdb/models/world/country'
require 'sportdb/models/world/continent'
require 'sportdb/models/world/region'
require 'sportdb/models/assoc'
require 'sportdb/models/assoc_assoc'
require 'sportdb/models/badge'
require 'sportdb/models/event'
require 'sportdb/models/event_comp'
require 'sportdb/models/event_ground'
require 'sportdb/models/event_team'
require 'sportdb/models/game'
require 'sportdb/models/game_comp'
require 'sportdb/models/goal'
require 'sportdb/models/ground'
require 'sportdb/models/group'
require 'sportdb/models/group_comp'
require 'sportdb/models/group_team'
require 'sportdb/models/league'
require 'sportdb/models/person'
require 'sportdb/models/race'
require 'sportdb/models/record'
require 'sportdb/models/roster'
require 'sportdb/models/round'
require 'sportdb/models/run'
require 'sportdb/models/season'
require 'sportdb/models/team'
require 'sportdb/models/team_comp'
require 'sportdb/models/track'
require 'sportdb/models/stat'
require 'sportdb/models/stat_data'
require 'sportdb/models/team_stat'
require 'sportdb/models/player_stat'

require 'sportdb/models/stats/alltime_standing'
require 'sportdb/models/stats/alltime_standing_entry'
require 'sportdb/models/stats/event_standing'
require 'sportdb/models/stats/event_standing_entry'
require 'sportdb/models/stats/group_standing'
require 'sportdb/models/stats/group_standing_entry'

require 'sportdb/models/utils'   # e.g. GameCursor

## add backwards compatible n convenience namespace
###  move to forward.rb ?? - why? why not??
module SportDb
  Models = Model
end


require 'sportdb/schema'       # NB: requires sportdb/models (include SportDB::Models)

require 'sportdb/finders/date'
require 'sportdb/finders/scores'

require 'sportdb/utils'
require 'sportdb/utils_date'
require 'sportdb/utils_group'
require 'sportdb/utils_map'
require 'sportdb/utils_record'
require 'sportdb/utils_round'
require 'sportdb/utils_scores'
require 'sportdb/utils_teams'
require 'sportdb/utils_goals'
require 'sportdb/matcher'
require 'sportdb/calc'

require 'sportdb/finders/goals'   # no: requires FixturesHelpers

require 'sportdb/readers/assoc'
require 'sportdb/readers/event'
require 'sportdb/readers/game'
require 'sportdb/readers/ground'
require 'sportdb/readers/league'
require 'sportdb/readers/race'
require 'sportdb/readers/record'
require 'sportdb/readers/race_team'
require 'sportdb/readers/season'
require 'sportdb/readers/squad'    # roster
require 'sportdb/readers/team'
require 'sportdb/readers/track'
require 'sportdb/reader'

require 'sportdb/lang'

require 'sportdb/updater'
require 'sportdb/deleter'
require 'sportdb/stats'


###############
# optional: for convenience add some finders etc. for known fixtures
#
#  only used for sportdb/console.rb
#   and  sportdb/tasks/test.rb  -> rename to tasks.rb?
#
#  todo/fix => remove from here and move into console.rb and tasks.rb

require 'sportdb/data/keys'
require 'sportdb/data/models'     # add convenience finders for known fixtures


# Some helpful aliases
PlayerStat = SportDb::Model::PlayerStat
Person = PersonDb::Model::Person
StatData = SportDb::Model::StatData
TeamStat = SportDb::Model::TeamStat


module SportDb

  def self.banner
    "sportdb/#{VERSION} on Ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) [#{RUBY_PLATFORM}]"
  end

  def self.root
    "#{File.expand_path( File.dirname(File.dirname(__FILE__)) )}"
  end

  def self.config_path
    "#{root}/config"
  end

  def self.data_path
    "#{root}/data"
  end

  def self.test_data_path
    "#{root}/test/data"
  end


  def self.lang
    # todo/fix: find a better way for single instance ??
    #  will get us ruby warning:  instance variable @lang not initialized   => find a better way!!!
    #   just use @lang w/o .nil?  e.g.
    #  @lang =|| Lang.new   why? why not??  or better use @@lang =|| Lang.new  for class variable!!!
     if @lang.nil?
       @lang = Lang.new
     end
     @lang
  end


  def self.main
    ## Runner.new.run(ARGV) - old code
    require 'sportdb/cli/main'
  end

  def self.create
    CreateDb.new.up
    ConfDb::Model::Prop.create!( key: 'db.schema.sport.version', value: VERSION )
  end

  def self.read_setup( setup, include_path )
    reader = Reader.new( include_path )
    reader.load_setup( setup )
  end

  def self.read_all( include_path )   # convenience helper
    read_setup( 'setups/all', include_path )
  end

  def self.read_builtin
    read_setup( 'setups/all', data_path )
  end


  # load built-in (that is, bundled within the gem) named plain text seeds
  # - pass in an array of pairs of event/seed names e.g.
  #   [['at.2012/13', 'at/2012_13/bl'],
  #    ['cl.2012/13', 'cl/2012_13/cl']] etc.

  def self.read( ary, include_path )
    reader = Reader.new( include_path )
    ## todo: check kind_of?( Array ) or kind_of?(String) to support array or string
    ary.each do |name|
      reader.load( name )
    end
  end


  # delete ALL records (use with care!)
  def self.delete!
    puts '*** deleting sport table records/data...'
    Deleter.new.run
  end # method delete!

  def self.update!
    puts '*** update event fixtures...'
    Updater.new.run
  end


  def self.stats
    stats = Stats.new
    stats.tables
    stats.props
  end

  def self.tables
    Stats.new.tables
  end

  ### fix:
  ## remove - use ConfDb.dump or similar -- add api depreciated
  def self.props
    Stats.new.props
  end

  def self.setup_in_memory_db
    # Database Setup & Config

    ActiveRecord::Base.logger = Logger.new( STDOUT )
    ## ActiveRecord::Base.colorize_logging = false  - no longer exists - check new api/config setting?

    ## NB: every connect will create a new empty in memory db
    ActiveRecord::Base.establish_connection(
                           adapter:  'sqlite3',
                           database: ':memory:' )

    ## build schema
    LogDb.create
    ConfDb.create
    TagDb.create
    WorldDb.create
    PersonDb.create
    SportDb.create

    ## read builtins - why? why not?
    SportDb.read_builtin
  end # setup_in_memory_db (using SQLite :memory:)


  def self.load_plugins

    @found  ||= []
    @loaded ||= {}
    @files  ||= Gem.find_files( 'sportdb_plugin.rb' )

    puts "#{@files.size} plugin files found:"
    @files.each do |file|
      puts "  >#{file}<"
    end
    
    ## todo: extract version and name of gem?
    puts "normalized/match pattern:"
    @files.each do |file|
      if file =~ /sportdb-([a-z]+)-(\d\.\d.\d)/
        puts "  >#{$1}< | >#{$2}<"
        @found << file
      else
        puts "*** error: ignoring plugin script >#{file}< not matching gem naming pattern"
      end
    end
    
    @found.each do |file|
      begin
        puts  "loading plugin script #{file}"
        require file
      rescue LoadError => e
        puts "*** error loading plugin script #{file.inspect}: #{e.message}. skipping..."
      end
    end

  end

end  # module SportDb


#SportDb::load_plugins


if __FILE__ == $0
  SportDb.main
else
   ## say hello
  puts SportDb.banner
end
