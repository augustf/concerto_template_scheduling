module ConcertoTemplateScheduling
  class Engine < ::Rails::Engine
    isolate_namespace ConcertoTemplateScheduling

    # The engine name will be the name of the class
    # that contains the URL helpers for our routes.
    engine_name 'template_scheduling'

    def plugin_info(plugin_info_class)
      @plugin_info ||= plugin_info_class.new do
        
        # Make the engine's controller accessible at /template-scheduling
        add_route("template-scheduling", ConcertoTemplateScheduling::Engine)

        # Some code to run at app boot
        init do
          Rails.logger.info "ConcertoTemplateScheduling: Initialization code is running"
        end

        # show the schedule details alongside each screen

        add_controller_hook "ScreensController", :show, :before do
          @schedules = Schedule.where(:screen_id => @screen.id)
          # reject the schedules that specify templates that have been deleted
          @schedules.reject!{|s| s.template.nil?}
        end

        add_view_hook "ScreensController", :screen_details, :partial => "concerto_template_scheduling/screens/screen_link"

        # show that the template is in use
  
        add_controller_hook "TemplatesController", :show, :before do
          @schedules = Schedule.where(:template_id => @template.id)
        end

        add_view_hook "TemplatesController", :template_details, :partial => "concerto_template_scheduling/templates/in_use_by"

        # influence which template is the effective template for a screen

        add_controller_hook "Screen", :effective_template, :before do
          # self is the screen model instance
          if @template.nil?
            schedules = Schedule.active.where(:screen_id => self.id)
            schedules.reject! {|s| !s.is_effective? }
            @template = schedules.first.template if !schedules.empty?
          end
        end

        # delete schedules when a screen is deleted

        add_controller_hook "ScreensController", :destroy, :after do
          Schedule.destroy_all(:screen_id => @screen.id)
        end

      end
    end
  end
end
