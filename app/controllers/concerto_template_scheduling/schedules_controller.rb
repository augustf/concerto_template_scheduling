require_dependency "concerto_template_scheduling/application_controller"

module ConcertoTemplateScheduling
  class SchedulesController < ApplicationController
    # GET /schedules
    # GET /schedules.json
    def index
      @schedules = Schedule.all
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @schedules }
      end
    end
  
    # GET /schedules/1
    # GET /schedules/1.json
    def show
      @schedule = Schedule.find(params[:id])
  
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
      auth!

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @schedule }
      end
    end
  
    # GET /schedules/1/edit
    def edit
      @schedule = Schedule.find(params[:id])
    end
  
    # POST /schedules
    # POST /schedules.json
    def create
      @schedule = Schedule.new(schedule_params)
      respond_to do |format|
        if @schedule.save
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
  
      respond_to do |format|
        if @schedule.update_attributes(schedule_params)
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
