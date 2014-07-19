
module SportDb
  module Model

class StatData < ActiveRecord::Base
  belongs_to :stat
  belongs_to :team
  belongs_to :event
  belongs_to :person, :class_name => 'PersonDb::Model::Person', :foreign_key => 'person_id'
end # Stat

  end # Model
end # SportDB
