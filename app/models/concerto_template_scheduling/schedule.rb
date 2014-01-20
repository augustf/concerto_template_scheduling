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
        'display_when' => 1
      }
    end

    # Create a new configuration hash if one does not already exist.
    # Called during `after_initialize`, where a config may or may not exist.
    def create_config
      self.config = {} if !self.config
      self.config = default_config().merge(self.config)
      self.display_when = self.config['display_when']
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
  end
end
