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

        # The following hooks allow integration into the main Concerto app
        # at the controller and view levels.

        add_controller_hook "ScreensController", :show, :before do
          @schedules = Schedule.where(:screen_id => @screen.id)
        end

        add_view_hook "ScreensController", :screen_details, :partial => "concerto_template_scheduling/screens/screen_link"
      end
    end
  end
end
