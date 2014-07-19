
#### note ---
## uses PersonDb namespace!!!!!
#
# move to models/person/person.rb  - why? why not??


module PersonDb
  module Model

### extends "basic" person model in PersonDb
class Person

  has_many :goals
  has_many :stats, :through => :stat_data, class_name: 'SportDb::Model::StatData'
  has_many :stat_data, class_name: 'SportDb::Model::StatData'

end  # class Person


  end # module Model
end # module PersonDb

