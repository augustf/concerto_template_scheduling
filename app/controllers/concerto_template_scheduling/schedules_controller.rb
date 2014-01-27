require_dependency "concerto_template_scheduling/application_controller"

module ConcertoTemplateScheduling
  class SchedulesController < ApplicationController
    # since scheduled templates are basically an extended feature of a screen
    # if the user can update the screen then they can crud scheduled templates

    # GET /schedules
    # GET /schedules.json
    def index
      @schedules = Schedule.all
      # ignore the schedules that belong to screens we cant read
      # or schedules where the template has been deleted
      @schedules.reject! { |s| !can?(:read, s.screen) || s.template.nil? }
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @schedules }
      end
    end
  
    # GET /schedules/1
    # GET /schedules/1.json
    def show
      @schedule = Schedule.find(params[:id])
      auth! :action => :read, :object => @schedule.screen

      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @schedule }
      end
    end
  
    # GET /schedules/new
    # GET /schedules/new.json
    def new
      @schedule = Schedule.new
      if !params[:screen_id].nil?
        # TODO: Error handling
        @schedule.screen = Screen.find(params[:screen_id])
      end
      auth! :action => :update, :object => @schedule.screen

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @schedule }
      end
    end
  
    # GET /schedules/1/edit
    def edit
      @schedule = Schedule.find(params[:id])
      auth! :action => :update, :object => @schedule.screen
    end
  
    # POST /schedules
    # POST /schedules.json
    def create
      @schedule = Schedule.new(schedule_params)
      auth! :action => :update, :object => @schedule.screen
      respond_to do |format|
        if @schedule.save
          process_notification(@schedule, {:screen_id => @schedule.screen_id, :screen_name => @schedule.screen.name,
            :template_id => @schedule.template.id, :template_name => @schedule.template.name }, 
            :key => 'concerto_template_scheduling.schedule.create', :owner => current_user, :action => 'create')

          format.html { redirect_to @schedule, notice: 'Schedule was successfully created.' }
          format.json { render json: @schedule, status: :created, location: @schedule }
        else
          format.html { render action: "new" }
          format.json { render json: @schedule.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /schedules/1
    # PUT /schedules/1.json
    def update
      @schedule = Schedule.find(params[:id])
      auth! :action => :update, :object => @schedule.screen

      respond_to do |format|
        if @schedule.update_attributes(schedule_params)
          process_notification(@schedule, {:screen_id => @schedule.screen_id, :screen_name => @schedule.screen.name,
            :template_id => @schedule.template.id, :template_name => @schedule.template.name }, 
            :key => 'concerto_template_scheduling.schedule.update', :owner => current_user, :action => 'update')

          format.html { redirect_to @schedule, notice: 'Schedule was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @schedule.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /schedules/1
    # DELETE /schedules/1.json
    def destroy
      @schedule = Schedule.find(params[:id])
      auth! :action => :update, :object => @schedule.screen
      process_notification(@schedule, {:screen_id => @schedule.screen_id, :screen_name => @schedule.screen.name,
        :template_id => @schedule.template.id, :template_name => @schedule.template.name }, 
        :key => 'concerto_template_scheduling.schedule.destroy', :owner => current_user, :action => 'destroy')
      @schedule.destroy
  
      respond_to do |format|
        format.html { redirect_to schedules_url }
        format.json { head :no_content }
      end
    end

    def schedule_params
      params.require(:schedule).permit(*ConcertoTemplateScheduling::Schedule.form_attributes)
    end
  end
end
