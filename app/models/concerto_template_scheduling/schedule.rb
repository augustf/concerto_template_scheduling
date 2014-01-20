module ConcertoTemplateScheduling
  class Schedule < ActiveRecord::Base
    include ActiveModel::ForbiddenAttributesProtection

    DISPLAY_WHEN = {
      I18n.t('concerto_template_scheduling.never') => 0, 
      I18n.t('concerto_template_scheduling.always') => 1, 
      I18n.t('concerto_template_scheduling.as_scheduled') => 2
    }

    belongs_to :screen
    belongs_to :template
    
    attr_accessor :display_when
    attr_accessor :config
    attr_accessor :from_time
    attr_accessor :to_time

    after_initialize :create_config
    after_find :load_config
    before_validation :save_config

    validates_associated :screen
    validates_presence_of :screen, :message => 'must be selected'
    # do not require uniqueness because the same template may be scheduled
    # for different time frames with different occurrence criteria
    # validates_uniqueness_of :template_id, :scope => :screen_id

    validates_associated :template
    validates_presence_of :template, :message => 'must be selected'

    # Specify the default configuration hash.
    # This will be used if a configuration doesn't exist.
    #
    # @return [Hash{String => String, Number}] configuration hash.
    def default_config
      {
        'display_when' => 1,
        'from_time' => '12:00am',
        'to_time' => '11:59pm'
      }
    end

    # Create a new configuration hash if one does not already exist.
    # Called during `after_initialize`, where a config may or may not exist.
    def create_config
      self.config = {} if !self.config
      self.config = default_config().merge(self.config)
      self.display_when = self.config['display_when']
      self.from_time = self.config['from_time']
      self.to_time = self.config['to_time']
      self.config
    end

    # Load a configuration hash.
    # Converts the JSON data stored for the schedule into the configuration.
    # Called during `after_find`.
    def load_config
      self.config = JSON.load(self.data)
    end

    # Prepare the configuration to be saved.
    # Compress the config hash back into JSON to be stored in the database.
    # Called during `before_validation`.
    def save_config
      self.config['display_when'] = self.display_when
      self.data = JSON.dump(self.config)
    end

# TODO: make sure these formats are locale-ized!

    # Setter for the start time.  If a hash is passed, convert that into a DateTime object and then a string.
    # Otherwise, just set it like normal.  This is a bit confusing due to the differences in how Ruby handles
    # times between 1.9.x and 1.8.x.
    def start_time=(_start_time)
      if _start_time.kind_of?(Hash)
        #write_attribute(:start_time, Time.parse("#{_start_time[:date]} #{_start_time[:time]}").to_s(:db))
        write_attribute(:start_time, DateTime.strptime("#{_start_time[:date]} #{_start_time[:time]}", "%m/%d/%Y %l:%M %p").to_s(:db))
      else
        write_attribute(:start_time, _start_time)
      end
    end

    # See start_time=.
    def end_time=(_end_time)
      if _end_time.kind_of?(Hash)
        write_attribute(:end_time, DateTime.strptime("#{_end_time[:date]} #{_end_time[:time]}", "%m/%d/%Y %l:%M %p").to_s(:db))
      else
        write_attribute(:end_time, _end_time)
      end
    end

    def is_effective?
      # if it is during the valid time frame
      # TODO! complete
      # and it is either marked as always
      # or it falls within the schedule and it is between the from_time to_time
    end

  end
end
