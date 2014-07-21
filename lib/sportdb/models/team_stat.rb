
module SportDb
  module Model

# TeamStats
#
# Contains the primary statistics for a team.  Could be on a per-game
#  basis, per event, or all-time (no game, no event).  A team will
#  have many TeamStats and can also have many generic StatData items
#
# redCards
# yellowCards
# totalGoals
# goalsConceded
# wins
# losses
# draws

class TeamStat < ActiveRecord::Base

  has_one :team
  has_one :game
  has_one :event

  end # class
  end # module Model
end # module SportDb
