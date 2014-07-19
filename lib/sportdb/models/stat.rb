
module SportDb
  module Model

class Stat < ActiveRecord::Base
  has_many :events, :through => :stat_data
  has_many :teams, :through => :stat_data
  has_many :people, :class_name => 'PersonDb::Model::Person', :foreign_key => 'person_id', :through => :stat_datas
end # Stat

  end # Model
end # SportDB
