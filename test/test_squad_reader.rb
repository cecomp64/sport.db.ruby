# encoding: utf-8

###
#  to run use
#     ruby -I ./lib -I ./test test/test_squad_reader.rb
#  or better
#     rake -I ./lib test


require 'helper'

class TestSquadReader < MiniTest::Unit::TestCase

  def setup
    WorldDb.delete!
    SportDb.delete!
    PersonDb.delete!
    
    SportDb.read_builtin   # add 2014 season

    add_world_cup_2014
    add_mls

    assert_equal 2, League.count
    assert_equal 2, Event.count
  end

  def add_world_cup_2014

    leaguereader = LeagueReader.new( SportDb.test_data_path )
    leaguereader.read( 'world-cup/leagues' )

    assert_equal 1, League.count

    l = League.find_by_key!( 'world' )
    assert_equal 'World Cup', l.title

    gamereader = GameReader.new( SportDb.test_data_path )
    gamereader.read( 'world-cup/2014/cup' )

    assert_equal 1, Event.count
  end

  def add_mls

    # import regional information
    WorldDb.read(['continents', 'north-america/countries', 'north-america/us-united-states/regions', 'north-america/us-united-states/cities'], SportDb.test_data_path + '/world.db')

    leaguereader = LeagueReader.new( SportDb.test_data_path )
    leaguereader.read( 'major-league-soccer/leagues' )

    l = League.find_by_key!( 'mls' )
    assert_equal 'Major League Soccer', l.title

    SportDb.read_setup('setups/teams', SportDb.test_data_path + '/major-league-soccer')

    gamereader = GameReader.new( SportDb.test_data_path )
    gamereader.read( 'major-league-soccer/2014/mls' )

  end

  def test_br
    br  = Country.create!( key: 'br', title: 'Brazil', code: 'BRA', pop: 1, area: 1)
    
    ## read persons
    personreader = PersonReader.new( SportDb.test_data_path )
    personreader.read( 'players/south-america/br-brazil/players', country_id: br.id ) 

    assert_equal 30, Person.count

    bra = Team.create!( key: 'bra', title: 'Brazil', code: 'BRA', country_id: br.id )


    event = Event.find_by_key!( 'world.2014' )

    reader = SquadReader.new( SportDb.test_data_path )
    reader.read( 'world-cup/2014/squads/br-brazil', team_id: bra.id, event_id: event.id )

    assert_equal 23, Roster.count
  end  # method test_br


  def test_de
    de  = Country.create!( key: 'de', title: 'Germany', code: 'GER', pop: 1, area: 1)

    ## read persons
    personreader = PersonReader.new( SportDb.test_data_path )
    personreader.read( 'players/europe/de-deutschland/players', country_id: de.id ) 

    assert_equal 27, Person.count

    ger = Team.create!( key: 'ger', title: 'Germany', code: 'GER', country_id: de.id )

    event = Event.find_by_key!( 'world.2014' )

    reader = SquadReader.new( SportDb.test_data_path )
    reader.read( 'world-cup/2014/squads/de-deutschland', team_id: ger.id, event_id: event.id )

    assert_equal 3, Roster.count
  end  # method test_de


  def test_uy
    uy = Country.create!( key: 'uy', title: 'Uruguay', code: 'URU', pop: 1, area: 1)

    assert_equal 0, Person.count
    assert_equal 0, Roster.count

    uru = Team.create!( key: 'uru', title: 'Uruguay', code: 'URU', country_id: uy.id )

    event = Event.find_by_key!( 'world.2014' )

    reader = SquadReader.new( SportDb.test_data_path )
    reader.read( 'world-cup/2014/squads/uy-uruguay', team_id: uru.id, event_id: event.id )

    assert_equal 23, Roster.count
    assert_equal 23, Person.count
  end  # method test_uy


  def test_jp
    jp = Country.create!( key: 'jp', title: 'Japan', code: 'JPN', pop: 1, area: 1)

    assert_equal 0, Person.count
    assert_equal 0, Roster.count

    jpn = Team.create!( key: 'jpn', title: 'Japan', code: 'JPN', country_id: jp.id )

    event = Event.find_by_key!( 'world.2014' )

    reader = SquadReader.new( SportDb.test_data_path )
    reader.read( 'world-cup/2014/squads/jp-japan', team_id: jpn.id, event_id: event.id )

    assert_equal 23, Roster.count
    assert_equal 23, Person.count
  end  # method test_jp

  def test_mls

    test_team = "chicago"
    event = Event.find_by_key!("mls.2014")
    team =  Team.find_by_key!(test_team)

    # Read in rosters and stats
    squadreader = SquadReader.new(SportDb.test_data_path)
    squadreader.read("major-league-soccer/2014/squads/#{test_team}-2014", {event_id: event.id, team_id: team.id})

    # Should have a few of the following stats...
    check_mls_stats(event, team)

    # Test updates
    #   Reload the same data, make sure above assertions still hold
    squadreader.read("major-league-soccer/2014/squads/#{test_team}-2014", {event_id: event.id, team_id: team.id})
    check_mls_stats(event, team)

    #   Load some new data - has one updated stat
    squadreader.read("major-league-soccer/2014/squads/#{test_team}_updated-2014", {event_id: event.id, team_id: team.id})
    check_mls_stats(event, team, 1)
  end

  def check_mls_stats(event, team, updated=0)
    # Should be 28 people
    roster = SportDb::Model::Roster.where(:event_id => event.id, :team_id => team.id)
    if (roster.count != 28)
      puts "++ ROSTER MISMATCH ++"
      roster.each do |r|
        puts "++  #{r.person.name}"
      end
    end

    assert_equal 28, roster.count

    #   (25) Sean Johnson
    #   $$ pos: G, age: 25, starts: 24, subIns: 0, saves: 64, goalsConceded: 37, foulsCommitted: 0, foulsSuffered: 2, yellowCards: 0, redCards: 0, wins: 0, losses: 0, draws: 0
    sjohnson = Person.where(name: "Sean Johnson")
    assert 1, sjohnson.count
    sjohnson = sjohnson[0]
    
    sjohnson_stats = sjohnson.player_stats.where(event_id: event.id, team_id: team.id)
    assert_equal 1, sjohnson_stats.count

    if (updated == 1)
      assert_equal 100, sjohnson_stats[0].goalsConceded
    else
      assert_equal 37, sjohnson_stats[0].goalsConceded
    end

    assert_equal 64, sjohnson_stats[0].saves
    assert_equal 0, sjohnson_stats[0].redCards

    #   (19) Harrison Shipp
    #   $$ pos: F, age: 0, starts: 20, subIns: 3, totalGoals: 6, totalShots: 31, shotsOnTarget: 13, goalAssists: 5, foulsCommitted: 9, foulsSuffered: 14, yellowCards: 0, redCards: 0, 
    hshipp = Person.where(name: "Harrison Shipp")
    assert 1, hshipp.count
    hshipp = hshipp[0]

    hshipp_stats = hshipp.player_stats.where(event_id: event.id, team_id: team.id)
    assert_equal 1, hshipp_stats.count
    assert_equal 20, hshipp_stats[0].starts
    assert_equal 6, hshipp_stats[0].totalGoals
    assert_equal 5, hshipp_stats[0].goalAssists

  end
end # class TestSquadReader
