module ConcertoTemplateScheduling
  class Schedule < ActiveRecord::Base
    include ActiveModel::ForbiddenAttributesProtection

    DISPLAY_NEVER=0
    DISPLAY_ALWAYS=1
    DISPLAY_AS_SCHEDULED=2
    DISPLAY_CONTENT_EXISTS=3

    DISPLAY_WHEN = {
      I18n.t('concerto_template_scheduling.never') => DISPLAY_NEVER, 
      I18n.t('concerto_template_scheduling.always') => DISPLAY_ALWAYS, 
      I18n.t('concerto_template_scheduling.as_scheduled') => DISPLAY_AS_SCHEDULED,
      I18n.t('concerto_template_scheduling.content_exists') => DISPLAY_CONTENT_EXISTS
    }

    belongs_to :screen
    belongs_to :template
    
    attr_accessor :config

    after_initialize :create_config
    after_find :load_config
    before_validation :save_config

    validates_associated :screen
    validates_presence_of :screen, :message => I18n.t('concerto_template_scheduling.must_be_selected')
    # do not require uniqueness because the same template may be scheduled
    # for different time frames with different occurrence criteria
    # validates_uniqueness_of :template_id, :scope => :screen_id

    validates_associated :template
    validates_presence_of :template, :message => I18n.t('concerto_template_scheduling.must_be_selected')

    validate :from_time_must_precede_to_time

    def from_time_must_precede_to_time
      if Time.zone.parse(self.config['from_time']) > Time.zone.parse(self.config['to_time'])
        errors.add(:base, I18n.t('concerto_template_scheduling.from_time_must_precede_to_time'))
      end
    end

    def self.active
      where("start_time < :now AND end_time > :now", {:now => Clock.time})
    end

    def self.form_attributes
      attributes = [:screen_id, :template_id,  
        {:start_time => [:time, :date]}, {:end_time => [:time, :date]}, 
        {:config => [:display_when, :from_time, :to_time, :feed_id, :scheduling_criteria]}]
    end

    # Specify the default configuration hash.
    # This will be used if a configuration doesn't exist.
    #
    # @return [Hash{String => String, Number}] configuration hash.
    def default_config
      {
        'display_when' => DISPLAY_ALWAYS,
        'from_time' => '12:00am',
        'to_time' => '11:59pm'
      }
    end

    # Create a new configuration hash if one does not already exist.
    # Called during `after_initialize`, where a config may or may not exist.
    def create_config
      self.start_time ||= Time.zone.parse("12:00am", Clock.time + ConcertoConfig[:start_date_offset].to_i.days)
      self.end_time ||= Time.zone.parse("11:59pm", Clock.time + ConcertoConfig[:start_date_offset].to_i.days + ConcertoConfig[:default_content_run_time].to_i.days)

      self.config = {} if !self.config
      self.config = default_config().merge(self.config)
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

    def schedule_in_words
      s = IceCube::Schedule.new(self.start_time)
      s.add_recurrence_rule(RecurringSelect.dirty_hash_to_rule(self.config['scheduling_criteria']))
      s.to_s
    end

    def is_effective?
      effective = false

      # if it is during the valid/active time frame and the template still exists
      if Clock.time >= self.start_time && Clock.time <= self.end_time && !self.template.nil?
        # and it is within the viewing window for the day
        if Clock.time >= Time.parse(self.config['from_time']) && Clock.time <= Time.parse(self.config['to_time'])
          # and it is either marked as always shown
          if self.config['display_when'].to_i == DISPLAY_ALWAYS
            effective = true
          elsif self.config['display_when'].to_i == DISPLAY_CONTENT_EXISTS
            # or if we detect actual content on the specified feed
            if !self.feed.nil? && !self.feed.approved_contents.active.where('kind_id != 4').empty?
              effective = true
            end
          elsif self.config['display_when'].to_i == DISPLAY_AS_SCHEDULED
            s = IceCube::Schedule.new(self.start_time)
            s.add_recurrence_rule(RecurringSelect.dirty_hash_to_rule(self.config['scheduling_criteria']))
            effective = s.occurs_on? Clock.time
          end
        end
      end

      effective
    end

    def feed
      if self.config.include?('feed_id')
        f = Feed.find(self.config['feed_id'].to_i)
      end
      f
    end

    def selectable_feeds
      if !self.screen.nil?
        feeds = Feed.all
        ability = Ability.new(self.screen)
        feeds.reject { |feed| !ability.can?(:read, feed) }
      end
    end

  end
end
