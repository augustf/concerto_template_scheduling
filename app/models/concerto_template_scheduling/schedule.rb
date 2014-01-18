module ConcertoTemplateScheduling
  class Schedule < ActiveRecord::Base
    belongs_to :screen
    belongs_to :template
    
    attr_accessible :data, :end_time, :start_time

    validates_associated :screen
    validates_presence_of :screen_id
    validates_presence_of :screen, :message => 'must exist'
    validates_uniqueness_of :template_id, :scope => :screen_id

    validates_associated :template
    validates_presence_of :template_id
    validates_presence_of :template, :message => 'must exist'

  end
end
