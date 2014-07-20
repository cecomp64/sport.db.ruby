# encoding: utf-8

module SportDb
  module Model

class Event < ActiveRecord::Base

  belongs_to :league
  belongs_to :season

if ActiveRecord::VERSION::MAJOR == 3
  has_many :rounds, order: 'pos'  # all (fix and flex) rounds
  has_many :groups, order: 'pos'
else
  has_many :rounds, -> { order('pos') }  # all (fix and flex) rounds
  has_many :groups, -> { order('pos') }
end

  has_many :games, :through => :rounds

  has_many :event_teams,  class_name: 'EventTeam'
  has_many :teams, :through => :event_teams

  has_many :event_grounds,  class_name: 'EventGround'
  has_many :grounds, :through => :event_grounds

  #has_many :stats, :through => :stat_data, class_name: 'StatData'
  has_many :stat_data, class_name: 'StatData'


  before_save :on_before_save


  def add_teams_from_ary!( team_keys )
    ## move to depreciated? used in event reader? why? why not?
    team_keys.each do |team_key|
      team = Team.find_by_key!( team_key )
      self.teams << team
    end
  end

  def on_before_save
    # event key is composite of league + season (e.g. at.2012/13) etc.
    self.key = "#{league.key}.#{season.key}"
  end
  
  def title
    "#{league.title} #{season.title}"
  end


  #####################
  ## convenience helper for text parser/reader

  ###
  ## fix: use/add  to_teams_table( rec )  for reuse
  #
  ##  @known_teams = @event.known_teams_table


  def known_teams_table
    @known_teams_table ||= TextUtils.build_title_table_for( teams )
  end # method known_teams_table

end # class Event

  end # module Model
end # module SportDb
