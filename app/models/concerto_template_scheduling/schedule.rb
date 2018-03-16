module ConcertoTemplateScheduling
  class Schedule < ActiveRecord::Base
    include ActiveModel::ForbiddenAttributesProtection
    include PublicActivity::Common if defined? PublicActivity::Common

    DISPLAY_NEVER=0
    DISPLAY_AS_SCHEDULED=2
    DISPLAY_CONTENT_EXISTS=3

    def self.display_when_options
      {
        I18n.t('concerto_template_scheduling.never') => DISPLAY_NEVER, 
        I18n.t('concerto_template_scheduling.as_scheduled') => DISPLAY_AS_SCHEDULED,
        I18n.t('concerto_template_scheduling.content_exists') => DISPLAY_CONTENT_EXISTS
      }
    end

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
    validate :schedule_must_be_defined

    def from_time_must_precede_to_time
      if Time.zone.parse(self.config['from_time']) > Time.zone.parse(self.config['to_time'])
        errors.add(:base, I18n.t('concerto_template_scheduling.from_time_must_precede_to_time'))
      end
    end

    def schedule_must_be_defined
      if self.config['display_when'].to_i == DISPLAY_AS_SCHEDULED
        if self.config['scheduling_criteria'].empty?
          errors.add(:base, I18n.t('concerto_template_scheduling.schedule_must_be_defined'))
        end
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
        'display_when' => DISPLAY_AS_SCHEDULED,
        'from_time' => ConcertoConfig[:content_default_start_time],
        'to_time' => ConcertoConfig[:content_default_end_time]
      }
    end

    # Create a new configuration hash if one does not already exist.
    # Called during `after_initialize`, where a config may or may not exist.
    def create_config
      Time.use_zone(screen.time_zone) do
        self.start_time ||= Time.zone.parse(ConcertoConfig[:content_default_start_time], Clock.time + ConcertoConfig[:start_date_offset].to_i.days)
        self.end_time ||= Time.zone.parse(ConcertoConfig[:content_default_end_time], Clock.time + ConcertoConfig[:start_date_offset].to_i.days + ConcertoConfig[:default_content_run_time].to_i.days)
      end
      
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
      self.config['scheduling_criteria'] = '' if self.config['scheduling_criteria'] == 'null'
      self.config['from_time'] = self.config['from_time'].gsub(I18n.t('time.am'), "am").gsub(I18n.t('time.pm'), "pm")
      self.config['to_time'] = self.config['to_time'].gsub(I18n.t('time.am'), "am").gsub(I18n.t('time.pm'), "pm")
      self.data = JSON.dump(self.config)
    end

    # Setter for the start time.  If a hash is passed, convert that into a DateTime object and then a string.
    # Otherwise, just set it like normal.  This is a bit confusing due to the differences in how Ruby handles
    # times between 1.9.x and 1.8.x.
    def start_time=(_start_time)
      Time.use_zone(screen.time_zone) do
        if _start_time.kind_of?(Hash)
          # convert to time, strip off the timezone offset so it reflects local time
          t = DateTime.strptime("#{_start_time[:date]} #{_start_time[:time]}".gsub(I18n.t('time.am'), "am").gsub(I18n.t('time.pm'), "pm"), "#{I18n.t('time.formats.date_long_year')} %I:%M %P")
          write_attribute(:start_time, Time.zone.parse(Time.iso8601(t.to_s).to_s(:db)))
        else
          write_attribute(:start_time, _start_time)
        end
      end
    end

    # See start_time=.
    def end_time=(_end_time)
      Time.use_zone(screen.time_zone) do
        if _end_time.kind_of?(Hash)
          # convert to time, strip off the timezone offset so it reflects local time
          t = DateTime.strptime("#{_end_time[:date]} #{_end_time[:time]}".gsub(I18n.t('time.am'), "am").gsub(I18n.t('time.pm'), "pm"), "#{I18n.t('time.formats.date_long_year')} %I:%M %P")
          write_attribute(:end_time, Time.zone.parse(Time.iso8601(t.to_s).to_s(:db)))
        else
          write_attribute(:end_time, _end_time)
        end
      end
    end

    def schedule_in_words
      if !self.config['scheduling_criteria'].empty?
        s = IceCube::Schedule.new(self.start_time)
        s.add_recurrence_rule(RecurringSelect.dirty_hash_to_rule(self.config['scheduling_criteria']))
        s.to_s
      end
    end

    def is_effective?
      effective = false

      # if it is during the valid/active time frame and the template still exists
      # This should consider time from the perspective of the screen's timezone...  so we will use Clock.time.in_time_zone(screen.time_zone) instead,
      # espcially because the from_time and to_time in the config is stored without regard to timezone (ie: considered in terms of local time for the screen).
      Time.use_zone(screen.time_zone) do
        current_time = Clock.time.in_time_zone(screen.time_zone)
Rails.logger.debug("\n\ntemplate = #{template.name}\ncurrent_time = #{current_time}\nfrom_time = #{Time.zone.parse(self.config['from_time'])}\nself.start_time = #{self.start_time.in_time_zone(screen.time_zone)}\n")
        if current_time >= self.start_time && current_time <= self.end_time && !self.template.nil?
          # and it is within the viewing window for the day
          if current_time >= Time.zone.parse(self.config['from_time']) && current_time <= Time.zone.parse(self.config['to_time'])
            # and it is either marked as always shown
            if self.config['display_when'].to_i == DISPLAY_CONTENT_EXISTS
              # or if we detect actual content on the specified feed
              if !self.feed.nil? && !self.feed.approved_contents.active.where('kind_id != 4').empty?
                effective = true
              end
            elsif self.config['display_when'].to_i == DISPLAY_AS_SCHEDULED
              if !self.config['scheduling_criteria'].empty?
                s = IceCube::Schedule.new(self.start_time)
                s.add_recurrence_rule(RecurringSelect.dirty_hash_to_rule(self.config['scheduling_criteria']))
                effective = s.occurs_on? current_time
              else
                # no schedule was set
              end
            end
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
        feeds.to_a.reject { |feed| !ability.can?(:read, feed) }
      end
    end

  end
end
