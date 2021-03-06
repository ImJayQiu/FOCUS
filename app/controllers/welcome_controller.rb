require "date"

class WelcomeController < ApplicationController

    layout :resolve_layout

    def index

    end

    def thankyou

    end

    def home 

	# loading map based on user country
	$country_iso = Country.select(:iso).where(name: current_user.country)[0].iso

	# Initial condition year
	@current_year = DateTime.now.year
	@ic_year = @current_year-1..@current_year

	# Initial condition month 
	@current_month = DateTime.now.strftime("%m-%B")

	cm_number=@current_month[0,2].to_i

	@ic_month = Share::MONTHS 

	initial_sfm = 0.upto(5).map { |n| DateTime::MONTHNAMES.drop(1)[(cm_number + n) % 12]}
	@initial_sfm = initial_sfm.map {|m|m.to_date.strftime("%m-%B")}
	@sfm = [] 

	#### first ajax select initial month ###################### 
	#
	if params[:ic_month].present? # ajax pass value success

	    # selected initial month conver to int. 
	    ic_month = params[:ic_month][0,2].to_i 

	    # find next 6 month name 
	    sfmn = 0.upto(5).map { |n| DateTime::MONTHNAMES.drop(1)[(ic_month + n) % 12]}

	    # convert to %m-%B format
	    @sfm = sfmn.map {|m|m.to_date.strftime("%m-%B")}

	    if request.xhr?
		respond_to do |format|
		    format.json {
			render json: {sfm: @sfm}
		    }
		end
	    end

	end
	#####################################################################################
	#####################################################################################
	############## second ajax select start - end forecast month #######################

	@efm = [] 

	if params[:sfm].present?

	    @efm = []

	    ###### update initial month
	    new_icm = params[:new_icm][0,2].to_i

	    ##### find month range
	    sfmn_2 = 0.upto(5).map { |n| DateTime::MONTHNAMES.drop(1)[(new_icm + n) % 12]}

	    #### month formatting
	    @sfm_2 = sfmn_2.map {|m|m.to_date.strftime("%m-%B")}

	    ####### find index of start forecast month 
	    sfm_sel_index = @sfm_2.index(params[:sfm])

	    #### find range of end forecast month
	    @efm = @sfm_2[sfm_sel_index..-1] 

	    if request.xhr?
		respond_to do |format|
		    format.json {
			render json: {efm: @efm}
		    }
		end
	    end

	end

	###############################################################

	# select name of  datasets from database, only active datasets will show
	@model_name = Dataset.select(:id, :name).where(active: "Yes", dtype: "Model")
	@obs_name = Dataset.select(:id, :name).where(active: "Yes", dtype: "Observation")

	# year range of models and obs
	#@year_range = 1982..@current_year-1

    end



    def debug 

	# loading map based on user country
	$country_iso = Country.select(:iso).where(name: current_user.country)[0].iso

	# Initial condition year
	@current_year = DateTime.now.year
	@ic_year = @current_year-1..@current_year

	# Initial condition month 
	@current_month = DateTime.now.strftime("%m-%B")
	#@ic_month = "01".."12" 
	@ic_month = Share::MONTHS 


	# select name of  datasets from database, only active datasets will show
	@model_name = Dataset.select(:id, :name).where(active: "Yes", dtype: "Model")
	@obs_name = Dataset.select(:id, :name).where(active: "Yes", dtype: "Observation")

	# year range of models and obs
	@year_range = "1993".."2010"

    end


    def forecast 

	@forecast_progress = 0
	@is_forecast_running = false

	# loading map based on user country
	$country_iso = Country.select(:iso).where(name: current_user.country)[0].iso

	@country_domain = Country.select(:slon,:elon,:slat,:elat).where(name: current_user.country)[0]

	@def_slon = @country_domain.slon
	@def_elon = @country_domain.elon
	@def_slat = @country_domain.slat
	@def_elat = @country_domain.elat

	@c_lon = (@def_slon + (@def_elon-@def_slon)/2).to_i
	@c_lat = (@def_slat + (@def_elat-@def_slat)/2).to_i

	# Initial condition year
	@current_year = DateTime.now.year
	@ic_year = @current_year-1..@current_year

	# Initial condition month 
	@current_month = DateTime.now.strftime("%m-%B")

	cm_number=@current_month[0,2].to_i

	@ic_month = Share::MONTHS 

	initial_sfm = 0.upto(5).map { |n| DateTime::MONTHNAMES.drop(1)[(cm_number + n) % 12]}
	@initial_sfm = initial_sfm.map {|m|m.to_date.strftime("%m-%B")}
	@sfm = [] 

	#### first ajax select initial month ###################### 
	#
	if params[:ic_month].present? # ajax pass value success

	    # selected initial month conver to int. 
	    ic_month = params[:ic_month][0,2].to_i 

	    # find next 6 month name 
	    sfmn = 0.upto(5).map { |n| DateTime::MONTHNAMES.drop(1)[(ic_month + n) % 12]}

	    # convert to %m-%B format
	    @sfm = sfmn.map {|m|m.to_date.strftime("%m-%B")}

	    if request.xhr?
		respond_to do |format|
		    format.json {
			render json: {sfm: @sfm}
		    }
		end
	    end

	end
	#####################################################################################
	#####################################################################################
	############## second ajax select start - end forecast month #######################

	@efm = [] 

	if params[:sfm].present?

	    @efm = []

	    ###### update initial month
	    new_icm = params[:new_icm][0,2].to_i

	    ##### find month range
	    sfmn_2 = 0.upto(5).map { |n| DateTime::MONTHNAMES.drop(1)[(new_icm + n) % 12]}

	    #### month formatting
	    @sfm_2 = sfmn_2.map {|m|m.to_date.strftime("%m-%B")}

	    ####### find index of start forecast month 
	    sfm_sel_index = @sfm_2.index(params[:sfm])

	    #### find range of end forecast month
	    @efm = @sfm_2[sfm_sel_index..-1] 

	    if request.xhr?
		respond_to do |format|
		    format.json {
			render json: {efm: @efm}
		    }
		end
	    end

	end

	###############################################################

	# select name of  datasets from database, only active datasets will show
	@model_name = Dataset.select(:id, :name).where(active: "Yes", dtype: "Model")
	@obs_name = Dataset.select(:id, :name).where(active: "Yes", dtype: "Observation")

	# year range of models and obs
	#@year_range = "1993".."2010"
	@year_range = 1993..2018  #@current_year-2

    end



    def verification 

	@analysis_list = ["Climatology", "Standard Deviation", "Root Mean Square Error", "Anomaly Correlation Coefficient"]

	@forecast_progress = 0
	@is_forecast_running = false

	# loading map based on user country
	$country_iso = Country.select(:iso).where(name: current_user.country)[0].iso

	@country_domain = Country.select(:slon,:elon,:slat,:elat).where(name: current_user.country)[0]

	@def_slon = @country_domain.slon
	@def_elon = @country_domain.elon
	@def_slat = @country_domain.slat
	@def_elat = @country_domain.elat

	@c_lon = (@def_slon + (@def_elon-@def_slon)/2).to_i
	@c_lat = (@def_slat + (@def_elat-@def_slat)/2).to_i

	# Initial condition year
	@current_year = DateTime.now.year
	@ic_year = @current_year-1..@current_year

	# Initial condition month 
	@current_month = DateTime.now.strftime("%m-%B")

	cm_number=@current_month[0,2].to_i

	@ic_month = Share::MONTHS 

	initial_sfm = 0.upto(5).map { |n| DateTime::MONTHNAMES.drop(1)[(cm_number + n) % 12]}
	@initial_sfm = initial_sfm.map {|m|m.to_date.strftime("%m-%B")}
	@sfm = [] 

	#### first ajax select initial month ###################### 
	#
	if params[:ic_month].present? # ajax pass value success

	    # selected initial month conver to int. 
	    ic_month = params[:ic_month][0,2].to_i 

	    # find next 6 month name 
	    sfmn = 0.upto(5).map { |n| DateTime::MONTHNAMES.drop(1)[(ic_month + n) % 12]}

	    # convert to %m-%B format
	    @sfm = sfmn.map {|m|m.to_date.strftime("%m-%B")}

	    if request.xhr?
		respond_to do |format|
		    format.json {
			render json: {sfm: @sfm}
		    }
		end
	    end

	end
	#####################################################################################
	#####################################################################################
	############## second ajax select start - end forecast month #######################

	@efm = [] 

	if params[:sfm].present?

	    @efm = []

	    ###### update initial month
	    new_icm = params[:new_icm][0,2].to_i

	    ##### find month range
	    sfmn_2 = 0.upto(5).map { |n| DateTime::MONTHNAMES.drop(1)[(new_icm + n) % 12]}

	    #### month formatting
	    @sfm_2 = sfmn_2.map {|m|m.to_date.strftime("%m-%B")}

	    ####### find index of start forecast month 
	    sfm_sel_index = @sfm_2.index(params[:sfm])

	    #### find range of end forecast month
	    @efm = @sfm_2[sfm_sel_index..-1] 

	    if request.xhr?
		respond_to do |format|
		    format.json {
			render json: {efm: @efm}
		    }
		end
	    end

	end

	###############################################################

	# select name of  datasets from database, only active datasets will show
	@model_name = Dataset.select(:id, :name).where(active: "Yes", dtype: "Model")
	@obs_name = Dataset.select(:id, :name).where(active: "Yes", dtype: "Observation")

	# year range of models and obs
	#@year_range = "1993".."2010"
	@year_range = 1993..2018  #@current_year-2

    end



    def roc 

	# loading map based on user country
	$country_iso = Country.select(:iso).where(name: current_user.country)[0].iso

	@country_domain = Country.select(:slon,:elon,:slat,:elat).where(name: current_user.country)[0]

	@def_slon = @country_domain.slon
	@def_elon = @country_domain.elon
	@def_slat = @country_domain.slat
	@def_elat = @country_domain.elat

	@c_lon = (@def_slon + (@def_elon-@def_slon)/2).to_i
	@c_lat = (@def_slat + (@def_elat-@def_slat)/2).to_i


	# Initial condition year
	@current_year = DateTime.now.year
	@ic_year = @current_year-1..@current_year

	# Initial condition month 
	@current_month = DateTime.now.strftime("%m-%B")

	cm_number=@current_month[0,2].to_i

	@ic_month = Share::MONTHS 

	initial_sfm = 0.upto(5).map { |n| DateTime::MONTHNAMES.drop(1)[(cm_number + n) % 12]}
	@initial_sfm = initial_sfm.map {|m|m.to_date.strftime("%m-%B")}
	@sfm = [] 

	#### first ajax select initial month ###################### 
	#
	if params[:ic_month].present? # ajax pass value success

	    # selected initial month conver to int. 
	    ic_month = params[:ic_month][0,2].to_i 

	    # find next 6 month name 
	    sfmn = 0.upto(5).map { |n| DateTime::MONTHNAMES.drop(1)[(ic_month + n) % 12]}

	    # convert to %m-%B format
	    @sfm = sfmn.map {|m|m.to_date.strftime("%m-%B")}

	    if request.xhr?
		respond_to do |format|
		    format.json {
			render json: {sfm: @sfm}
		    }
		end
	    end

	end
	#####################################################################################
	#####################################################################################
	############## second ajax select start - end forecast month #######################

	@efm = [] 

	if params[:sfm].present?

	    @efm = []

	    ###### update initial month
	    new_icm = params[:new_icm][0,2].to_i

	    ##### find month range
	    sfmn_2 = 0.upto(5).map { |n| DateTime::MONTHNAMES.drop(1)[(new_icm + n) % 12]}

	    #### month formatting
	    @sfm_2 = sfmn_2.map {|m|m.to_date.strftime("%m-%B")}

	    ####### find index of start forecast month 
	    sfm_sel_index = @sfm_2.index(params[:sfm])

	    #### find range of end forecast month
	    @efm = @sfm_2[sfm_sel_index..-1] 

	    if request.xhr?
		respond_to do |format|
		    format.json {
			render json: {efm: @efm}
		    }
		end
	    end

	end

	###############################################################

	# select name of  datasets from database, only active datasets will show
	@model_name = Dataset.select(:id, :name).where(active: "Yes", dtype: "Model")
	@obs_name = Dataset.select(:id, :name).where(active: "Yes", dtype: "Observation")

	# year range of models and obs
	#@year_range = "1993".."2010"
	#@year_range = 1982..@current_year-2
	@year_range = 1993..2018  #@current_year-2

    end



    private


    def resolve_layout
	case action_name

	when "home", "roc", "forecast", "debug", "verification"

	    "home"

	when "index","thankyou"

	    "index"

	else

	    "application"

	end
    end

end
