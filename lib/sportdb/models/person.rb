
#### note ---
## uses PersonDb namespace!!!!!
#
# move to models/person/person.rb  - why? why not??


module PersonDb
  module Model

### extends "basic" person model in PersonDb
class Person

  has_many :goals
  has_many :stats, :through => :stat_data

end  # class Person


  end # module Model
end # module PersonDb

