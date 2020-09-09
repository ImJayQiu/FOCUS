require "date"
require "cdo"

class VerificationController < ApplicationController

    layout "home"


    def result 

	# start time
	s_total_time = Time.new

	@cdo = Cdo.new()

	@cdo.debug = true

	@ic_object = params[:ic_object]

	if @ic_object == "Temperture"
	    object_path = "temp"
	elsif @ic_object == "Precipitation"
	    object_path = "prec"
	end

	# initial conditions
	@ic_year = params[:ic_year]
	@ic_month = params[:ic_month]

	# CFS has problem, remove it
	@models = params[:models]

	# observation data group
	@obs_data = params[:obs_data]

	# hindcast year
	@sdy = params[:sdy]
	@edy = params[:edy]


	# start month of forecast
	@sfm = params[:sfm]

	# end month of forecast
	@efm = params[:efm]

	# forecast method id
	@method_all= params[:analysis_methods]

	# list method names from id
	#@method_all = Fmethod.find(params[:method_ids])
	#@method_all = @methods


	@user_id = current_user.id
	@country_domain = Country.select(:slon,:elon,:slat,:elat).where(name: current_user.country)[0]

	@slon = slon = @country_domain.slon
	@elon =	elon = @country_domain.elon
	@slat =	slat = @country_domain.slat
	@elat =	elat = @country_domain.elat

	#center point of domain
	@clon = slon+(elon-slon)/2
	@clat = slat+(elat-slat)/2


	#slon = params[:s_lon][0].to_i 
	#elon = params[:e_lon][0].to_i 
	#slat = params[:s_lat][0].to_i 
	#elat = params[:e_lat][0].to_i 

	dom_dir = [slon.to_i, elon.to_i, slat.to_i, elat.to_i].join('_')




	@commit = params[:commit] 

	if @commit == "Check Models"

	    @years_check = (@sdy..@edy).to_a.append(@ic_year).to_a

	    @data_check=[]

	    @models.each do |model|

		model_a = []

		mpath = Dataset.select(:dpath).where(name: model)[0].dpath

		mon = @ic_month[0,2]

		@years_check.each do |y|

		    check_file = "#{mpath}/#{object_path}/#{mon}/em_#{mon}_#{y}.nc"

		    if File.exist?(check_file)


		    else

			model_a << y 

		    end

		end #years.each

		@data_check << [model, model_a]

	    end #models.each


	    return

	else



	    ########## forecast month ###############

	    if @sfm[0,2].to_i < @efm[0,2].to_i 

		# if start forecast month is 02, end month is 06, then months will be 02,03,04,05,06
		@fm_range = (@sfm[0,2].to_i..@efm[0,2].to_i).to_a 

	    else

		#if start forecast month is 09, end month is 02, then the months will be 09,10,11,12 + 01,02
		@fm_range = (@sfm[0,2].to_i..12).to_a + (1..@efm[0,2].to_i).to_a 

	    end


	    # output months range as JJAS 
	    if @sfm == @efm 
		@fmonths = "#{@sfm[3...6]}"
	    else
		@fmonths = "#{@fm_range.map {|m|Date::ABBR_MONTHNAMES[m][0]}.join('')}"
	    end 


	    ####### number of forecast month ####################

	    if @efm.to_i < @sfm.to_i

		# if start month is 09, end month is 02, then number of months is 12 - 9 + 2 + 1 = 6 (12 - 9 did not count Dec. in, so plus 1 at the end)
		@fm_gap = 12 - @sfm.to_i + @efm.to_i + 1 

	    else

		# if start month is 02, end month is 09, then number of months is 9 - 2 + 1 = 8 (9 - 2 did not count Dep. in, so plus 1 at the end)
		@fm_gap = @efm.to_i - @sfm.to_i + 1

	    end

	    ########### initial month to forecast start  month ##################

	    if @ic_month.to_i > @sfm.to_i

		# if initial month is 10, start month is 02 then the lead time index will be 12 - 10 + 2 = 4 (11,12,1,2)
		@lead = 12 - @ic_month.to_i + @sfm.to_i  

	    else

		@lead = @sfm.to_i - @ic_month.to_i 

	    end

	    ######################################################################################
	    ##### create folder to keep output data ##########################################
	    #####################################################################################

	    # able to find historical result from this folder

	    output_root = "/home/focus/www/focus/public/analysis_output" 

	    # final output dir

	    @methods = @method_all.to_a 

	    f_dir = "#{@ic_object}_#{@ic_year}_#{@ic_month[0,2]}_#{@models.join('_')}_#{@obs_data}_#{@sdy}_#{@edy}_#{@sfm[0,2]}_#{@efm[0,2]}_#{@methods.join('_')}"

	    @output_dir = output_dir = "#{output_root}/#{dom_dir}/#{f_dir}"

	    @download_dir = "analysis_output/#{dom_dir}/#{f_dir}/"

	    ###########################################################################
	    ########### check if the result is there ############################### 
	    ###########################################################################

	    if Dir.exist?("#{output_dir}")

=begin

	    @fin_output = []	

	    @methods.each do |method| 

		if method == "MME1" then method_full_name = "Simple Mean Method (SMM)" end
		if method == "MME2" then method_full_name = "Weighted Average Method (WAM)" end
		if method == "PCR" then method_full_name = "Principal components regression (PCR)" end

		cp_file = Dir["#{output_dir}/cp_#{method}_*_rotate.png"].sort 

		@fin_output << {method: method, cp: cp_file, method_full_name: method_full_name}	

	    end 

	    return
=end

		rm_output_dir = "rm -R #{output_dir}"

		system rm_output_dir

	    end # if the result is already there, return.

	    #################################################################################
	    ################### new analysis : create folder #########################
	    #################################################################################

	    mkdir_cmd = "mkdir -p #{output_dir}"

	    system mkdir_cmd

	    if @methods.include? "PCR" 
		mkdir_pcr = "mkdir -p #{output_dir}/PCR/CFSv2"
		system(mkdir_pcr) 
	    end

	    #################################################################################
	    #################### CDO domain selection ##########################################
	    ##########################################################################

	    cdom = "#{slon},#{elon},#{slat},#{elat}"

	    #################################################################
	    ################## copy and merge obs data ###############################
	    ##########################################################################
	    #
	    # catch OBS data location
	    obspath = Dataset.select(:dpath).where(name: @obs_data)[0].dpath

	    ############################ obs data for forecast ####################################

	    @selobs = selobs=[]

	    (@sdy..@edy).to_a.each do |year|

		obfile = "#{obspath}/#{object_path}/#{@ic_month[0,2]}/ob_#{@ic_month[0,2]}_#{year}.nc"

		selobs << obfile

	    end # (@sdy..@edy).to_a.each do |year|


	    ############################ prepare obs data for verification  ####################################
	    ############################ prepare obs data for verification  ####################################
	    selverobs = []

	    if @sfm[0,2].to_i > @efm[0,2].to_i

		(@sfm[0,2].."12").to_a.each do |vfm|
		    (@sdy..(@edy.to_i-1).to_s).to_a.each do |vyear|

			#obfile = "#{obspath}/#{object_path}/#{@ic_month[0,2]}/ob_#{@ic_month[0,2]}_#{year}.nc"
			verobsfile = "#{obspath}/#{object_path}/#{vfm}/ob_#{vfm}_#{vyear}.nc"

			selverobs << verobsfile

		    end # (@sfm..@efm).to_a.each do |fm|
		end # (@sdy..@edy).to_a.each do |year|

		("01"..@sfm[0,2]).to_a.each do |vfm|
		    ((@sdy.to_i-1).to_s..@edy).to_a.each do |vyear|

			#obfile = "#{obspath}/#{object_path}/#{@ic_month[0,2]}/ob_#{@ic_month[0,2]}_#{year}.nc"
			verobsfile = "#{obspath}/#{object_path}/#{vfm}/ob_#{vfm}_#{vyear}.nc"

			selverobs << verobsfile

		    end # (@sfm..@efm).to_a.each do |fm|
		end # (@sdy..@edy).to_a.each do |year|


	    else

		(@sfm[0,2]..@efm[0,2]).to_a.each do |vfm|
		    (@sdy..@edy).to_a.each do |vyear|

			#obfile = "#{obspath}/#{object_path}/#{@ic_month[0,2]}/ob_#{@ic_month[0,2]}_#{year}.nc"
			verobsfile = "#{obspath}/#{object_path}/#{vfm}/ob_#{vfm}_#{vyear}.nc"

			selverobs << verobsfile

		    end # (@sfm..@efm).to_a.each do |fm|
		end # (@sdy..@edy).to_a.each do |year|


	    end 

	    ############################ end  prepare obs data for verification  ####################################

	    ############################  Process different OBS datasets #########################################

	    obs_merge = @cdo.mergetime(input: selobs.join(" ") )
	    verobs_merge = @cdo.mergetime(input: selverobs.join(" ") )

	    ### if select ERA5 as observation ############### 

	    if @obs_data == "ERA5"

		obs_sellonlat = @cdo.sellonlatbox(cdom, input: obs_merge, output: "#{output_dir}/obs_raw.nc")
		verobs_sellonlat = @cdo.sellonlatbox(cdom, input: verobs_merge, output: "#{output_dir}/obs_ver_raw.nc" )

		#raw_obs = @cdo.mulc(1000, input: obs_sellonlat, output: "#{output_dir}/obs_raw.nc", options: '-b f32' )
		#raw_obs = @cdo.mulc(1000, input: obs_sellonlat, output: "#{output_dir}/obs.nc", options: '-b f32')
		#raw_verobs = @cdo.mulc(1000, input: verobs_sellonlat, output: "#{output_dir}/obs_ver_raw.nc", options: '-b f32' )
		#raw_verobs = @cdo.mulc(1000, input: verobs_sellonlat, output: "#{output_dir}/obs_ver.nc", options: '-b f32' )

		## change latitude orientation of obs data

		#final_obs = "cdo invertlat #{output_dir}/obs_raw.nc #{output_dir}/obs.nc"
		#final_verobs = "cdo invertlat #{output_dir}/obs_ver_raw.nc #{output_dir}/obs_ver.nc"

		#system raw_obs
		#system raw_verobs
		#system final_obs
		#system final_verobs

	    else

		obs_final = @cdo.sellonlatbox(cdom, input: obs_merge, output: "#{output_dir}/obs_raw.nc" )
		verobs_final = @cdo.sellonlatbox(cdom, input: verobs_merge, output: "#{output_dir}/obs_ver_raw.nc" )

	    end

	    ## time average data of obs
	    ################# climatoloty verification of OBS ###################	
	    if @obs_data=="ERA5"


		obs_mmd = "cp #{output_dir}/obs_raw.nc #{output_dir}/obs.nc"
		obs_ver_mmd = "cp #{output_dir}/obs_ver_raw.nc #{output_dir}/obs_ver.nc"
		system obs_mmd
		system obs_ver_mmd

		# Mr.Raj version
		#climatology_obs = "cdo timmean -yearsum #{output_dir}/obs_ver.nc #{output_dir}/obs_climatology.nc"
		# Itesh version
		climatology_obs = "cdo timmean #{output_dir}/obs_ver.nc #{output_dir}/obs_climatology.nc"

	    elsif @obs_data=="CHIRPS"

		obs_mmd = "cdo divc,30 #{output_dir}/obs_raw.nc #{output_dir}/obs.nc"
		obs_ver_mmd = "cdo divc,30 #{output_dir}/obs_ver_raw.nc #{output_dir}/obs_ver.nc"
		system obs_mmd
		system obs_ver_mmd

		climatology_obs = "cdo chname,prec,climatology -setunit,'mm/day' -timmean #{output_dir}/obs_ver.nc #{output_dir}/obs_climatology.nc"

	    end

	    climatology_obs_download = "cdo chname,prec,climatology -setunit,'mm/day' #{output_dir}/obs_climatology.nc #{output_dir}/obs_climatology_dl.nc"

	    system climatology_obs
	    system climatology_obs_download

	    ###################### SD of OBS dataset verification #################################
	    sd_obs = "cdo timstd #{output_dir}/obs_ver.nc #{output_dir}/obs_sd.nc"

	    system sd_obs

	    ############### prepare for ACC verification ############################
	    obs_sub = "cdo sub #{output_dir}/obs_ver.nc #{output_dir}/obs_climatology.nc #{output_dir}/obs_sub.nc"

	    system obs_sub

	    obs_anom = "cdo div #{output_dir}/obs_sub.nc #{output_dir}/obs_sd.nc #{output_dir}/obs_anom.nc"

	    system obs_anom

	    ###################################################################################
	    ################### Prepare model datasets for forecast ###########################
	    ################### copy and merge models data ####################################
	    ###################################################################################


	    fin_mods = [] #### selected model files based on the initial condition and hindcast 
	    seldomains = [] # for params.txt file
	    pcrmods = [] ### models for PCR forecast


	    @models.each_with_index do |model,i|

		selmods = [] 

		mpath = Dataset.select(:dpath).where(name: @models[i])[0].dpath

		##########################################################################
		# select models based on hindcast_years and ic_year
		##########################################################################

		(@sdy..@edy).to_a.append(@ic_year).each do |year|

		    mfile = "#{mpath}/#{object_path}/#{@ic_month[0,2]}/em_#{@ic_month[0,2]}_#{year}.nc"

		    selmods << mfile

		    ###### prepare data for PCR function ####################################
		    #
		    if @models[i] == "CFSv2" and @methods.include? "PCR" 
			rawfile = "#{mpath}/#{object_path}/#{@ic_month[0,2]}/#{@ic_month[0,2]}_#{year}.nc"
			pcrmods << rawfile
		    end

		    ##########################################################################

		end #(@sdy..@edy).to_a.append(@ic_year).each do |year|

		mmt = "cdo mergetime #{selmods.join(' ')} #{output_dir}/#{@models[i]}_mergetime.nc"
		msll = "cdo sellonlatbox,#{cdom} #{output_dir}/#{@models[i]}_mergetime.nc #{output_dir}/#{@models[i]}_merge.nc"

		system mmt
		system msll

		##########################################################################
		########### cut dataset by using country domain ################
		##########################################################################

		#seldomain = "cdo sellonlatbox,#{cdom} #{output_dir}/#{@models[i]}_merge.nc #{output_dir}/#{@models[i]}.nc "
		seldomain = "cp #{output_dir}/#{@models[i]}_merge.nc #{output_dir}/#{@models[i]}.nc "
		#ver_model = "cdo delete,year=#{@ic_year} #{output_dir}/#{@models[i]}_merge.nc #{output_dir}/#{@models[i]}_ver.nc "

		rm_seldomain = "rm #{output_dir}/#{@models[i]}_merge.nc"

		system(seldomain)  		# final model data for forecast 
		system(rm_seldomain)	# remove used model data for forecast 

		##########################################################################
		########## select forecast month ##############################
		##########################################################################

		if @models[i]=="ECMWF" || @models[i]=="UKMO" || @models[i]=="Meteo-France" 

		    @selmon_ecmwf = "cdo selmon,#{@fm_range.join(',')} #{output_dir}/#{@models[i]}.nc #{output_dir}/#{@models[i]}_sellevel.nc" 

		    ################ models[i]_mean: prepare for model.nc for python forecast script #########################
		    @runmean_ecmwf = "cdo yearmean #{output_dir}/#{@models[i]}_sellevel.nc #{output_dir}/#{@models[i]}_mean.nc" 

		    system	@selmon_ecmwf 
		    system	@runmean_ecmwf 


		    ########### for verification #####################

		    ##### ECMWF use different timesteps to keep lead data  ###########
		    #### timmean will take average of all value and generate only one timestep value
		    @climatology_ecmwf = "cdo timmean #{output_dir}/#{@models[i]}_sellevel.nc #{output_dir}/#{@models[i]}_climatology.nc" 

		    @climatology_ecmwf_download = "cdo chname,prec,climatology -setunit,'mm/day' #{output_dir}/#{@models[i]}_climatology.nc #{output_dir}/#{@models[i]}_climatology_dl.nc" 

		    ### sd of ecmwf #####################
		    @sd_ecmwf = "cdo timstd #{output_dir}/#{@models[i]}.nc #{output_dir}/#{@models[i]}_sd.nc" 

		    ### RMSE of ecmwf #####################
		    @rmse_ecmwf = "cdo sqrt -timmean -sqr -sub #{output_dir}/obs_ver.nc #{output_dir}/#{@models[i]}.nc #{output_dir}/#{@models[i]}_rmse.nc"

		    #########################################################################
		    #### anom = sub of obs and model /  std of model
		    ######### ACC of ECMWF #########################################

		    #### model value - model mean ########################
		    @sub_ecmwf = "cdo sub #{output_dir}/#{@models[i]}_mean.nc #{output_dir}/#{@models[i]}_climatology.nc #{output_dir}/#{@models[i]}_sub.nc" 

		    @anom_ecmwf = "cdo div #{output_dir}/#{@models[i]}_sub.nc #{output_dir}/#{@models[i]}_sd.nc #{output_dir}/#{@models[i]}_anom.nc"

		    @acc_ecmwf = "cdo timcor #{output_dir}/#{@models[i]}_anom.nc #{output_dir}/obs_anom.nc #{output_dir}/#{@models[i]}_acc.nc"

		    ###########  for verification #####################
		    system	@climatology_ecmwf 
		    system	@climatology_ecmwf_download 
		    system	@sub_ecmwf 
		    system	@sd_ecmwf 
		    system	@rmse_ecmwf 
		    system	@anom_ecmwf 
		    system	@acc_ecmwf 

		else

		    #### list lead level [0.5,1.5,....,6.5] 
		    @lead_level = (0.5..6.5).step(1).to_a 

		    ### sellevel @lead_level[3,2] from index 3 to index 5
		    @sellevel = @lead_level[@lead.to_i, @fm_gap.to_i] 

		    @sellevel_data = "cdo sellevel,#{@sellevel.join(',')} #{output_dir}/#{@models[i]}.nc #{output_dir}/#{@models[i]}_sellevel.nc" 
		    ##### the models which put leads as levels 
		    @vertmean_data = "cdo vertmean #{output_dir}/#{@models[i]}_sellevel.nc #{output_dir}/#{@models[i]}_mean.nc" 

		    system @sellevel_data

		    system @vertmean_data

		    ############################# for verification ################################################


		    #### mean data of each model #################
		    @climatology_data = "cdo timmean #{output_dir}/#{@models[i]}_mean.nc #{output_dir}/#{@models[i]}_climatology.nc" 
		    @climatology_data_download = "cdo chname,prec,climatology -setunit,'mm/day' #{output_dir}/#{@models[i]}_climatology.nc #{output_dir}/#{@models[i]}_climatology_dl.nc" 


		    #### SD data of each model ######################
		    @sd_data = "cdo timstd #{output_dir}/#{@models[i]}_mean.nc #{output_dir}/#{@models[i]}_sd.nc" 


		    ##### delete ic_year from model data, rmse each level then mean 
		    @rmse_data = "cdo sqrt -timmean -sqr -sub #{output_dir}/obs_ver.nc #{output_dir}/#{@models[i]}_mean.nc #{output_dir}/#{@models[i]}_rmse.nc"

		    #########################################################################
		    #### anom of model = sub of obs_climatology and model / model sd 
		    ######### ACC of each model ############################

		    @sub_data = "cdo sub #{output_dir}/#{@models[i]}_mean.nc #{output_dir}/#{@models[i]}_climatology.nc #{output_dir}/#{@models[i]}_sub.nc" 

		    @anom_data = "cdo div #{output_dir}/#{@models[i]}_sub.nc #{output_dir}/#{@models[i]}_sd.nc #{output_dir}/#{@models[i]}_anom.nc" 

		    @acc_data = "cdo timcor #{output_dir}/#{@models[i]}_anom.nc -invertlat #{output_dir}/obs_anom.nc #{output_dir}/#{@models[i]}_acc.nc"
		    ############### for verification ##############################
		    system @climatology_data		# climatology verification 
		    system @climatology_data_download	# climatology verification 
		    system @sd_data				# standard deviation 
		    system @rmse_data			# root mean square error 

		    ############### acc verification ###############
		    system @sub_data
		    system @anom_data 
		    system @acc_data


		end

		fin_mods << "#{output_dir}/#{@models[i]}_mean.nc"

	    end #@models.each do |model|

	    ###############################################################
	    ################ prepare PCR lead time data ####################
	    ###############################################################

	    pcrmods.each do |pcr_file|

		#lead time start from 0
		#pcr_lead = (@lead.to_i..@fm_gap.to_i).step(1).to_a.join(',') 
		pcr_lead = (@lead.to_i..(@lead.to_i+@fm_gap.to_i-1)).step(1).to_a.join(',') 

		# for txt file, debug 
		@pcr_lead2 = (@lead.to_i..(@lead.to_i+@fm_gap.to_i-1)).step(1).to_a.join(',') 

		# lf_name : local file name
		lf_name = pcr_file.last(10).to_s

		# change working directory to output PCR folder
		if @methods.include? "PCR" 
		    Dir.chdir("#{output_dir}/PCR/CFSv2/") do 

			# select lead time based on user's selection, ncks -d L,1,4 in.nc out.nc means select variable L from index 1 to index 4
			select_lead = "ncks -d L,#{pcr_lead[0]},#{pcr_lead[-1]} #{pcr_file} l_#{lf_name}"
			system(select_lead)

			# average lead time
			lead_time_mean = "ncwa -a L l_#{lf_name} lm_#{lf_name}"
			system(lead_time_mean)

			# select domain
			pcr_sel_domain = @cdo.sellonlatbox(cdom, input: "lm_#{lf_name}", output: "slm_#{lf_name}")

			# remove unused file
			rm_lead = "rm l_#{lf_name}"
			system(rm_lead)

			rm_lead_mean = "rm lm_#{lf_name}"
			system(rm_lead_mean)

		    end #Dir.chdir("#{output_dir}/PCR/CFSv2/") do 

		end #if @methods.include? "PCR" 

	    end #pcrmods.each do |pcr_file|


	    if @methods.include? "PCR" 
		Dir.chdir("#{output_dir}/PCR/CFSv2/") do 

		    # merge all data
		    # create pcr input file, must be lower cases, the upper cases will be the final output files
		    slm_merge = "cdo mergetime slm_*.nc #{output_dir}/pcr_CFSv2.nc" 

		    system(slm_merge)

		end #Dir.chdir("#{output_dir}/PCR/CFSv2/") do 

	    end #if @methods.include? "PCR" 

	    ###############################################################
	    ################ finished :  prepare PCR lead time data ####################
	    ###############################################################



	    ###############################################################
	    ########### create models merge file ##############
	    ###############################################################

	    final_models_merge = "cdo merge #{fin_mods.join(' ')} #{output_dir}/model.nc" 
	    system final_models_merge  

	    if @methods.include? "PCR" 
		pcr_fin_mods = fin_mods.to_a - ["#{output_dir}/CFSv2_mean.nc"]

		# create pcr input file, must be lower cases, the upper cases will be the final output files
		system "cdo merge #{pcr_fin_mods.join(' ')} #{output_dir}/pcr_models.nc"
	    end

	    #for debug
	    @pcrmods2 = pcr_fin_mods

	    ##########################################################################
	    ################## copy color bar file of Grads  #########################
	    ##########################################################################


	    #system "cp /FOCUS_DATA/GRADS_source/cbar/*.gs #{output_dir}/."

	    ##########################################################################
	    ################## Verification Climatology plot ###############################
	    ##########################################################################


	    Dir.chdir(output_dir) do


		climatology_files = Dir["*_climatology.nc"] # mean file of each models for verification 

		climatology_files.each do |plot_nc|

		    model = plot_nc.split("_")[0]

		    if model == "obs"
			model_name = @obs_data
		    else
			model_name = model
		    end


		    system "cdo gradsdes #{plot_nc}"

		    ############################ Climatology GrADS plot #############################
		    gs = File.open("#{plot_nc}.gs", "w")
		    gs.puts("reinit")
		    gs.puts("open #{plot_nc[0...-3]}.ctl")
		    gs.puts("set grads off")
		    gs.puts("set gxout grfill")
		    gs.puts("set font 1")
		    gs.puts("/FOCUS_RUN/GRADS_source/cbar/Climatology.gs")
		    gs.puts("/FOCUS_RUN/GRADS_source/basemap/basemap.gs O 15 1 H")
		    gs.puts("d prec")
		    gs.puts("/FOCUS_RUN/GRADS_source/cbar/1_xcbar.gs 9 9.3 1.5 7.0 ")
		    gs.puts("draw title Climatology (mm/day) of #{model_name} \\ Year: #{@sdy} to #{@edy} | Months:#{@fmonths}")
		    gs.puts("printim #{plot_nc}.png png white")
		    gs.puts("quit")
		    gs.close

		    ##############################################################

		    Dir.chdir(output_dir) do
			system "grads -lbc 'exec #{plot_nc}.gs'"
		    end

		    ##############################################################

		end #climatology_files.each do |clim|

	    end #Dir.chdir(output_dir) do

	    ##########################################################################
	    ################## Verification Standard Deviation plot ###############################
	    ##########################################################################

	    Dir.chdir(output_dir) do

		sd_files = Dir["*_sd.nc"] # mean file of each models for verification 

		sd_files.each do |plot_nc|

		    model = plot_nc.split("_")[0]

		    if model == "obs"
			model_name = @obs_data
		    else
			model_name = model
		    end


		    system "cdo gradsdes #{plot_nc}"

		    ############################ SD GrADS plot #############################
		    gs = File.open("#{plot_nc}.gs", "w")
		    gs.puts("reinit")
		    gs.puts("open #{plot_nc[0...-3]}.ctl")
		    gs.puts("set grads off")
		    gs.puts("set gxout grfill")
		    gs.puts("set font 1")
		    gs.puts("set strsiz 0.12")
		    gs.puts("/FOCUS_RUN/GRADS_source/cbar/sd.gs")
		    gs.puts("/FOCUS_RUN/GRADS_source/basemap/basemap.gs O 15 1 H")
		    gs.puts("d prec")
		    gs.puts("/FOCUS_RUN/GRADS_source/cbar/1_xcbar.gs 9 9.3 1.5 7.0 ")
		    gs.puts("draw title Standard Deviation of #{model_name} \\ Year: #{@sdy} to #{@edy} | Months:#{@fmonths}")
		    gs.puts("printim #{plot_nc}.png png white")
		    gs.puts("quit")
		    gs.close
		    ##############################################################

		    Dir.chdir(output_dir) do
			system "grads -lbc 'exec #{plot_nc}.gs'"
		    end

		    ##############################################################

		end #sd_files.each do |sd|

	    end #Dir.chdir(output_dir) do

	    ##########################################################################
	    ################## Verification Root Mean Square Error RMSE ###############################
	    ##########################################################################

	    Dir.chdir(output_dir) do

		rmse_files = Dir["*_rmse.nc"] # mean file of each models for verification 

		rmse_files.each do |plot_nc|

		    model = plot_nc.split("_")[0]

		    if model == "obs"
			model_name = @obs_data
		    else
			model_name = model
		    end


		    system "cdo gradsdes #{plot_nc}"

		    ############################ RMSE GrADS plot #############################
		    gs = File.open("#{plot_nc}.gs", "w")
		    gs.puts("reinit")
		    gs.puts("open #{plot_nc[0...-3]}.ctl")
		    gs.puts("set grads off")
		    gs.puts("set gxout grfill")
		    gs.puts("set font 1")
		    gs.puts("set strsiz 0.12")
		    gs.puts("/FOCUS_RUN/GRADS_source/cbar/rmse.gs")
		    gs.puts("/FOCUS_RUN/GRADS_source/basemap/basemap.gs O 15 1 H")
		    gs.puts("d prec")
		    gs.puts("/FOCUS_RUN/GRADS_source/cbar/1_xcbar.gs 9 9.3 1.5 7.0 ")
		    gs.puts("draw title Root Mean Square Error of #{model_name} \\ Year: #{@sdy} to #{@edy} | Months:#{@fmonths}")
		    gs.puts("printim #{plot_nc}.png png white")
		    gs.puts("quit")
		    gs.close
		    ##############################################################

		    Dir.chdir(output_dir) do
			system "grads -lbc 'exec #{plot_nc}.gs'"
		    end

		    ##############################################################

		end #rmse_files.each do |rmse|

	    end #Dir.chdir(output_dir) do


	    ##########################################################################
	    ################## Verification ACC plot ###############################
	    ##########################################################################

	    Dir.chdir(output_dir) do

		acc_files = Dir["*_acc.nc"] # mean file of each models for verification 

		acc_files.each do |plot_nc|

		    model = plot_nc.split("_")[0]

		    if model == "obs"
			model_name = @obs_data
		    else
			model_name = model
		    end


		    system "cdo gradsdes #{plot_nc}"

		    ############################ ACC GrADS plot #############################
		    gs = File.open("#{plot_nc}.gs", "w")
		    gs.puts("reinit")
		    gs.puts("open #{plot_nc[0...-3]}.ctl")
		    gs.puts("set grads off")
		    gs.puts("set gxout grfill")
		    gs.puts("set font 1")
		    gs.puts("set strsiz 0.12")
		    gs.puts("/FOCUS_RUN/GRADS_source/cbar/corr.gs")
		    gs.puts("/FOCUS_RUN/GRADS_source/basemap/basemap.gs O 15 1 H")
		    gs.puts("d prec")
		    gs.puts("/FOCUS_RUN/GRADS_source/cbar/1_xcbar.gs 9 9.3 1.5 7.0 ")
		    gs.puts("draw title Anomaly Correlation Coefficient of #{model_name} \\ Year: #{@sdy} to #{@edy} | Months:#{@fmonths}")
		    gs.puts("printim #{plot_nc}.png png white")
		    gs.puts("quit")
		    gs.close
		    ##############################################################

		    Dir.chdir(output_dir) do
			system "grads -lbc 'exec #{plot_nc}.gs'"
		    end

		    ##############################################################

		end #rmse_files.each do |rmse|

	    end #Dir.chdir(output_dir) do


	    ##########################################################################
	    ################## create params txt ###############################
	    ##########################################################################

	    params_path = "#{output_dir}/params.txt"

	    country_iso = Country.select(:iso).where(name: current_user.country)[0]

	    txt = File.open(params_path, "w")

	    txt.puts "#{@ic_year}"

	    txt.puts "#{@ic_month}"

	    txt.puts "#{@models.join(" ")}/#{@obs_data}"

	    txt.puts "#{@sdy}/#{@edy}"

	    if @sfm == @efm 
		txt.puts "#{@sfm[3...6]}"
	    else
		txt.puts "#{@fm_range.map {|m|Date::ABBR_MONTHNAMES[m][0]}.join('')}"
	    end 

	    txt.puts "#{@methods.join(" ")}"

	    txt.puts "/FOCUS_RUN/CountryShape/#{country_iso.iso}/-#{country_iso.iso}_adm0"

	    txt.close

	    ################################################################
	    ############ Analysis based on selected methods  ###############
	    ################################################################

	    #@method_py = @method_all.pluck(:file_name) 

	    #@py_cmds = []

	    #@py_cmd_output = []

	    #@method_py.each do |py_f| 

	#	st = Time.new

		############ run python script #########################
	#	py_cmd = `time python /FOCUS_RUN/py_methods/#{py_f} #{output_dir.to_s}/` 
	#	py_cmd_check = "python /FOCUS_RUN/py_methods/#{py_f} #{output_dir.to_s}/" 
	#	@py_cmds << py_cmd_check 

	#	et = Time.new

	#	cmd_info ={file: py_f, time: (et - st).round(2)}

	#	@py_cmd_output << cmd_info

	 #   end

	    ####################################################	
	    ####### list final netcdf data result #################################
	    ###############################################################

	    @final_output = []	

	    @final_p_output = []

	    @methods.each do |method| 

		all_nc_file = Dir["#{output_dir}/#{method}_*.nc"] # select all method related file 
		series_nc_file = Dir["#{output_dir}/*_SERIES_*.nc"] # method input file 
		prob_nc_file = Dir["#{output_dir}/#{method}_PROB_FCST_*.nc"] 
		nc_file = all_nc_file - series_nc_file 

		@final_output << {method: method, nc_file: nc_file} # for plot	
		@final_p_output << {method: method, nc_file: prob_nc_file}	

	    end 


	    ###########################################################################
	    ############# Generate map from final NC file #############################################
	    ###############################################################

	    splot_time = Time.new 

	    @final_output.each do |final| # list output of each forecast method

		method = final[:method] # name of forecast method

		if method == "MME1" then method_full_name = "Simple Mean (SMM)" end
		if method == "MME2" then method_full_name = "Skilled Weighted Average (WAM)" end
		if method == "PCR" then method_full_name = "Principal Component Regression" end

		final[:nc_file].each do |nc| #list output netcdf of each forecast method

		    current_plot_nc = nc.split("/")[-1] # select only nc file name

		    @nc_vars = @cdo.showname(input: nc) # list var names 


		    ###################################################################

		    @nc_vars[0].split(" ").each do |var|

			if var.split("_")[0]== "anom" 
			    var_full = "Anomaly(mm/day)" 
			    var_cb = "Anomaly.gs"
			end

			if var.split("_")[0]== "corr" 
			    var_full = "Correlation" 
			    var_cb = "corr.gs"
			end

			if var.split("_")[0]== "dep"
			    var_full = "Departure(%)" 
			    var_cb = "Departure.gs"
			end

			if var.split("_")[0]== "above" 
			    var_full = "Above Normal"
			    var_cb = "Departure.gs"
			end
			if var.split("_")[0]== "avg"
			    var_full = "Average"
			    var_cb = "Departure.gs"
			end
			if var.split("_")[0]== "below" 
			    var_full = "Below Normal"
			    var_cb = "Departure.gs"
			end

			### for verification ###################
			if var.split("_")[0]== "prec" then var_full = "Principitation" end


			################# prepare GMT datasets #######################


			var_nc =  var.split("_")[0]

			if var.split("_")[0]== "prec" # if this is model mean data 
			    var_nc_name = "#{current_plot_nc[0..-4]}"
			else
			    var_nc_name = "#{method}_#{var}"
			end

			# catch nc file by selected variable name
			var_nc = "cdo selname,#{var} #{output_dir}/#{current_plot_nc} #{output_dir}/#{var_nc_name}.nc" 
			system var_nc

			################# end prepare GMT datasets #######################


			######################### GrADS plot for anom/dep/corr #####################################

			Dir.chdir(output_dir) do
			    var_ctl_nc = "cdo gradsdes #{var_nc_name}.nc" 
			    system var_ctl_nc

			    gs = File.open("#{var_nc_name}.gs", "w")
			    gs.puts("reinit")
			    gs.puts("open #{var_nc_name}.ctl")
			    gs.puts("set grads off")
			    gs.puts("set gxout grfill")
			    gs.puts("set font 1")
			    gs.puts("/FOCUS_RUN/GRADS_source/cbar/#{var_cb}")
			    gs.puts("/FOCUS_RUN/GRADS_source/basemap/basemap.gs O 15 1 H")
			    gs.puts("d #{var}")
			    gs.puts("/FOCUS_RUN/GRADS_source/cbar/1_xcbar.gs 9 9.3 1.5 7.0 ")
			    gs.puts("draw title #{var_full} of #{method_full_name} \\ Year: #{@sdy} to #{@edy} | Months:#{@fmonths}")
			    gs.puts("printim #{var_nc_name}_gr.png png white")
			    gs.puts("quit")
			    gs.close

			    system "grads -lbc 'exec #{var_nc_name}.gs'"
			end




			######################### GMT plot anom/dep/corr #####################################
			#
			gmtRR="-R#{slon-0.5}/#{elon+0.5}/#{slat-0.5}/#{elat+0.5}" 

			if (elon - slon).abs <= (elat-slat).abs 
			    gmtROTATE = "-P"
			else
			    gmtROTATE = ""
			end

			# Projection and size 3 inch
			gmtJJ="-JM5i" 

			# output ps file name
			gmtNAME_raw = "#{var_nc_name}" 

			# color bar

			if var_nc_name.split("_").include? "corr" 

			    gmtCPT="/FOCUS_DATA/GMT_source/cpt/corr3.cpt"
			    xscale="-Bx0.2"

			elsif var_nc_name.split("_").include? "anom" 

			    gmtCPT="/FOCUS_DATA/GMT_source/cpt/anom3.cpt"
			    xscale="-Bx1"

			elsif var_nc_name.split("_").include? "dep" 

			    gmtCPT="/FOCUS_DATA/GMT_source/cpt/dep_v3.cpt"
			    xscale="-Bx20"

			end

			# surface data file
			gmtGRD="/FOCUS_DATA/GMT_source/World_topo.grd"

			# netcdf datasets
			gmtNC_raw = "#{var_nc_name}.nc"
			gmtTITLE="#{method_full_name} Forecast - #{var_full}"

			step1 = "gmt grdimage #{gmtNC_raw} #{gmtRR} -Ba2f1g5 -BnWSe+t'#{gmtTITLE}' #{gmtJJ} -C#{gmtCPT} -V #{gmtROTATE} -K > #{gmtNAME_raw}.ps"

			step2 = "gmt pscoast #{gmtRR} #{gmtJJ} -B0 -Df -N1/2p -W1p -Slightblue -A10000 -K -O >> #{gmtNAME_raw}.ps"

			steptxt1 = "echo 3 -1.5 Hindcast: #{@sdy} to #{@edy} | gmt pstext -J -R0/6/0/8 -K -O >> #{gmtNAME_raw}.ps"

			steptxt2 = "echo 3 -2 Forecast months: #{@fmonths} #{@ic_year}-#{@ic_month[0..1]} | gmt pstext -J -R0/6/0/8 -K -O >> #{gmtNAME_raw}.ps"



			#step3 = "gmt psscale -Dx5.5i/0.1i+w10c/0.5c -C#{gmtCPT} -I #{xscale} -By -O >> #{gmtNAME_raw}.ps"
			step3 = "gmt psscale -D6.3/-1/12/0.5h -C#{gmtCPT} #{xscale} -By  -O >> #{gmtNAME_raw}.ps"

			output_png = "gmt psconvert #{gmtNAME_raw}.ps -Tg -A"

			#################################################
			Dir.chdir(output_dir) do
			    system step1
			    system step2
			    system steptxt1
			    system steptxt2
			    system step3
			    system output_png
			end

			##############################################################

		    end #@nc_vars[0].split(" ").each do |var|

		end   #final[:nc_file].each do |nc|

	    end #@final_output.each do |final|


	    eplot_time = Time.new 
	    @plot_time = (eplot_time - splot_time).round(2)

	    ####################################################	
	    ####### list final result #################################

	    @all_output = []	

	    @methods.each do |method| 

		if method == "MME1" then method_full_name = "Simple Mean (SMM)" end
		if method == "MME2" then method_full_name = "Skilled Weighted Average (WAM)" end
		if method == "PCR" then method_full_name = "Principal Component Regression" end
		#if method == "PCR" then method_full_name = "Principal components regression (PCR)" end


		nc_file = Dir["#{output_dir}/#{method}_*_*_*.nc"].sort 

		prec_file = Dir["#{output_dir}/#{method}_*_prec.png"].sort 
		prob_file = Dir["#{output_dir}/#{method}_*_prob.nc"].sort 

		@all_output << {method: method, nc: nc_file, prec: prec_file, prob: prob_file, method_full_name: method_full_name}	

	    end 

	    #####################################################################

	    #prob_file.each in line 790

	    @all_output.each do |output| 

		output[:prec].each do |params_prec|

		    path = params_prec.split("/")

		    domain = path[7].split("_") 

		    file_name = path[-1] # MME1_dep_prec.png 

		    output_dir = path[0..-2].join("/")

		    file_info = file_name.split("_") #["MME1", "dep", "prec.png"] 

		    method = file_info[0]
		    if method == "MME1" then method_full_name = "Simple Mean (SMM)" end
		    if method == "MME2" then method_full_name = "Skilled Weighted Average (WAM)" end
		    if method == "PCR" then method_full_name = "Principal Component Regression" end


		    parameters = path[8].split("_") # Precipitation_2020_04_GFDL-A06_GFDL-AER04_GFDL-B01_CFSv2_CanCM4i_CanSIPSv2_NASA-GEOSS2S_COLA-RSMAS-CCSM4_CHIRPS_1982_2018_05_09_MME1_MME2

		    obs_name = parameters[12] 

		    func = file_info[1]

		    if func == "anom" then func_full_name = "Anomaly(mm/day)" end
		    if func == "corr" then func_full_name = "Correlation" end
		    if func == "dep" then func_full_name = "Departure(%)" end

		    var = file_info[2].split(".")[0] # catch "prce" from "prec.png"

		    var_full_name = path[8].split("_")[0] 	

		    #@page_title = "#{var_full_name} forecast of #{method} - #{func_full_name} " 


		    ################# prepare GMT datasets #######################
		    Dir.chdir(output_dir) do

			main_nc_file = Dir["#{method}_#{obs_name}_*.nc"][0]

			var_nc = "#{func}_#{var}" # variable of NetCDF file

			var_nc_name = "#{method}_#{func}_#{var}" # output nc file after select variable

			# catch nc file by selected variable name
			var_nc = "cdo selname,#{var_nc} #{main_nc_file} #{var_nc_name}.nc" 
			system var_nc


			# create HiRes datasets for GMT plot
			gmt1m = "gmt grdsample #{var_nc_name}.nc -I1m -G#{var_nc_name}.gmt"
			system gmt1m
			################# end prepare GMT datasets #######################

			######################### GMT plot #####################################
			#
			gmtRR="-R#{slon}/#{elon}/#{slat}/#{elat}" 

			if (elon - slon).abs <= (elat-slat).abs 
			    gmtROTATE = "-P"
			    rotate_degree = "0"
			else
			    gmtROTATE = ""
			    rotate_degree = "90"
			end

			# Projection and size 5 inch
			gmtJJ="-JM5i" 

			# output ps file name
			gmtNAME = "FOCUS_#{var_nc_name}" 
			gmtNAME_raw = "FOCUS_#{var_nc_name}_raw" 

			# color bar

			if var_nc_name.split("_").include? "corr" 

			    gmtCPT="/FOCUS_DATA/GMT_source/cpt/corr3.cpt"
			    xscale="-Bx0.2"

			elsif var_nc_name.split("_").include? "anom" 

			    gmtCPT="/FOCUS_DATA/GMT_source/cpt/anom3.cpt"
			    xscale="-Bx1"

			elsif var_nc_name.split("_").include? "dep" 

			    gmtCPT="/FOCUS_DATA/GMT_source/cpt/dep_v3.cpt"
			    xscale="-Bx20"

			end

			# surface data file
			gmtGRD="/FOCUS_DATA/GMT_source/World_topo.grd"

			# netcdf datasets
			gmtNC = "#{var_nc_name}.gmt"
			gmtNC_raw = "#{var_nc_name}.nc"
			gmtTITLE="#{method_full_name} - #{func_full_name}"

			# create topo.i file, to plot surface data
			step1 = "gmt grdgradient #{gmtGRD} -A135 -Nt #{gmtRR} -G#{gmtNAME}.i"
			#step1_raw = "gmt grdgradient #{gmtGRD} -A135 -Nt #{gmtRR} -G#{gmtNAME_raw}.i"

			step2 = "gmt grdimage #{gmtNC} #{gmtRR} -I#{gmtNAME}.i -Ba2f1g5 -BnWSe+t'#{gmtTITLE}' #{gmtJJ} -C#{gmtCPT} -V #{gmtROTATE} -K > #{gmtNAME}.ps"
			step2_raw = "gmt grdimage #{gmtNC_raw} #{gmtRR} -Ba2f1g5 -BnWSe+t'#{gmtTITLE}' #{gmtJJ} -C#{gmtCPT} -V #{gmtROTATE} -K > #{gmtNAME_raw}.ps"

			step3 = "gmt pscoast #{gmtRR} #{gmtJJ} -B0 -Df -N1/2p -W1p -Slightblue -A10000 -K -O >> #{gmtNAME}.ps"
			step3_raw = "gmt pscoast #{gmtRR} #{gmtJJ} -B0 -Df -N1/2p -W1p -Slightblue -A10000 -K -O >> #{gmtNAME_raw}.ps"


			steptxt1 = "echo 3 -1.5 Hindcast: #{@sdy} to #{@edy} | gmt pstext -J -R0/6/0/8 -K -O >> #{gmtNAME}.ps"
			steptxt2 = "echo 3 -2 Forecast months: #{@fmonths} #{@ic_year}-#{@ic_month[0..1]} | gmt pstext -J -R0/6/0/8 -K -O >> #{gmtNAME}.ps"


			steptxt1_raw = "echo 3 -1.5 Hindcast: #{@sdy} to #{@edy} | gmt pstext -J -R0/6/0/8 -K -O >> #{gmtNAME_raw}.ps"
			steptxt2_raw = "echo 3 -2 Forecast months: #{@fmonths} #{@ic_year}-#{@ic_month[0..1]} | gmt pstext -J -R0/6/0/8 -K -O >> #{gmtNAME_raw}.ps"


			#step4 = "gmt psscale -Dx5.5i/0.1i+w10c/0.5c -C#{gmtCPT} -I #{xscale} -By -O >> #{gmtNAME}.ps"
			step4 = "gmt psscale -D6.3/-1/12/0.5h -C#{gmtCPT} #{xscale} -By  -O >> #{gmtNAME}.ps"

			#step4_raw = "gmt psscale -Dx5.5i/0.1i+w10c/0.5c -C#{gmtCPT} -I #{xscale} -By -O >> #{gmtNAME_raw}.ps"
			step4_raw = "gmt psscale -D6.3/-1/12/0.5h -C#{gmtCPT} #{xscale} -By  -O >> #{gmtNAME_raw}.ps"

			output_png_raw = "gmt psconvert #{gmtNAME_raw}.ps -Tg -A"

			output_png = "gmt psconvert #{gmtNAME}.ps -Tg -A"

			output_rotate = "convert #{gmtNAME}.png -rotate #{rotate_degree} #{gmtNAME}_rotate.png"

			output_rotate_raw = "convert #{gmtNAME_raw}.png -rotate #{rotate_degree} #{gmtNAME_raw}_rotate.png"
			#################################################
			#system step1
			#system step2
			#system step3
			#system steptxt1
			#system steptxt2
			#system step4
			#system output_png

			#system step1_raw
			#system step2_raw
			#system step3_raw
			#system steptxt1_raw
			#system steptxt2_raw
			#system step4_raw
			#system output_png_raw
			#system output_rotate_raw 

		    end #Dir.chdir(output_dir) do

		end # output[:prec].each do |param_prec| 

	    end	#@all_output.each do |output| 



	    #prec_file in 630
	    @all_output.each do |output| 

		output[:prec].each do |params_prob|


		    path = params_prob.split("/")

		    domain = path[7].split("_") 

		    #	@slon = slon = domain[0].to_i 
		    #	@elon = elon = domain[1].to_i 
		    #	@slat = slat = domain[2].to_i
		    #	@elat = elat = domain[3].to_i
		    #	@download_dir = path[6..-2].join("/")

		    file_name = path[-1] # MME1_dep_prec.png 

		    output_dir = path[0..-2].join("/")

		    file_info = file_name.split("_") #["MME1", "dep", "prec.png"] 

		    method = file_info[0]


		    if method == "MME1" then method_full_name = "Simple Mean" end
		    if method == "MME2" then method_full_name = "Skilled Weighted Average" end
		    if method == "PCR" then method_full_name = "Principal Components Regression" end
		    #if method == "PCR" then method_full_name = "Principal Components Regression (PCR)" end



		    func = "Tercile Probability Forecast" 

		    var = file_info[2].split(".")[0] # catch "prce" from "prec.png"

		    var_full_name = path[8].split("_")[0] 	

		    @page_title = "#{var_full_name} #{func} of #{method_full_name}" 


		    ########################## Probilities forecast plotting ################################

		    Dir.chdir(output_dir) do
			prob_nc = Dir["#{method}_PROB_FCST_*.nc"][0]
			#
			prob_split = "cdo splitvar #{prob_nc} #{method}_"
			system prob_split

			#### Prepare below, normal, above datasets ##############
			#
			below_fin = "cdo setrtoc,0,37,nan -mul #{method}_below_prob.nc -mul -gt #{method}_below_prob.nc #{method}_above_prob.nc -gt #{method}_below_prob.nc #{method}_avg_prob.nc #{method}_below_fin.nc"
			system below_fin

			avg_fin = "cdo setrtoc,0,37,nan -mul #{method}_avg_prob.nc -mul -gt #{method}_avg_prob.nc #{method}_below_prob.nc -gt #{method}_avg_prob.nc #{method}_above_prob.nc #{method}_avg_fin.nc"
			system avg_fin

			above_fin = "cdo setrtoc,0,37,nan -mul #{method}_above_prob.nc -mul -gt #{method}_above_prob.nc #{method}_below_prob.nc -gt #{method}_above_prob.nc #{method}_avg_prob.nc #{method}_above_fin.nc"
			system above_fin

			############ GMT plot ##########################################
			#
			# Projection and size 5 inch
			gmtJJ="-JM5i" 

			# output ps file name
			gmtNAME = "#{method}_PROB_final" 
			gmtNAME_h = "#{method}_PROB_final_h" 


			gmtRR="-R#{slon+0.5}/#{elon-0.5}/#{slat+0.5}/#{elat-0.5}" 

			if (elon - slon).abs <= (elat-slat).abs 
			    gmt_rotate = "-P"
			    rotate_degree = "0"
			else
			    gmt_rotate = ""
			    rotate_degree = "90"
			end

			# color bar

			below_CPT="/FOCUS_DATA/GMT_source/cpt/below.cpt"
			avg_CPT="/FOCUS_DATA/GMT_source/cpt/avg.cpt"
			above_CPT="/FOCUS_DATA/GMT_source/cpt/above.cpt"

			# netcdf datasets
			below_NC = "#{method}_below_fin.nc"
			avg_NC = "#{method}_avg_fin.nc"
			above_NC = "#{method}_above_fin.nc"
			#####################################

			# create HiRes datasets for GMT plot
			below_NC_h = "gmt grdsample #{below_NC} -T -I1m -G#{below_NC}.nc"
			avg_NC_h = "gmt grdsample #{avg_NC} -T -I1m -G#{avg_NC}.nc"
			above_NC_h = "gmt grdsample #{above_NC} -T -I1m -G#{above_NC}.nc"
			#system below_NC_h 
			#system avg_NC_h 
			#system above_NC_h 

			# surface data file
			gmtGRD="/FOCUS_DATA/GMT_source/World_topo.grd"


			####################### for hi-res map #################################
			# create topo.i file, to plot surface data
			step1_h = "gmt grdgradient #{gmtGRD} -A135 -Nt #{gmtRR} -G#{gmtNAME_h}.i"

			step2_1_h = "gmt grdimage #{below_NC}.nc #{gmtRR} -Ba5f2 -BnWSE+t'#{method_full_name} Probability Forecast' #{gmtJJ} -Q -C#{below_CPT} -K -V #{gmt_rotate} > #{gmtNAME_h}.ps"

			step2_2_h = "gmt grdimage #{avg_NC}.nc #{gmtRR} -Ba5f2 -BnWSE+t'#{method_full_name} Probability Forecast' #{gmtJJ} -Q -C#{avg_CPT} -K -V #{gmt_rotate} > #{gmtNAME_h}.ps"

			step2_3_h = "gmt grdimage #{above_NC}.nc #{gmtRR} -Ba5f2 -BnWSE+t'#{method_full_name} Probability Forecast' #{gmtJJ} -Q -C#{above_CPT} -K -V #{gmt_rotate} > #{gmtNAME_h}.ps"

			step3_h = "gmt pscoast #{gmtRR} #{gmtJJ} -B0 -Df -N3/2p -W1p -Slightblue -A10000 -K -O >> #{gmtNAME_h}.ps"

			#### plot colar bar for Hi-res ########################
			step4_1_h = "gmt psscale -Dx1c/-1c+w3c/0.5c+h -C#{below_CPT} -L -Bx+l#{"Below"} -K -O >> #{gmtNAME_h}.ps"

			step4_2_h = "gmt psscale -Dx5c/-1c+w3c/0.5c+h -C#{avg_CPT} -L -Bx+l#{"Avg"} -K -O >> #{gmtNAME_h}.ps"

			step4_3_h = "gmt psscale -Dx9c/-1c+w3c/0.5c+h -C#{above_CPT} -L -Bx+l#{"Above"} -O >> #{gmtNAME_h}.ps"

			# output jpg file
			output_pdf_h = "gmt psconvert #{gmtNAME_h}.ps -Tf -A"

			output_jpg_h = "gmt psconvert #{gmtNAME_h}.ps -Tj -A"

			output_png_h = "gmt psconvert #{gmtNAME_h}.ps -Tg -A"

			output_rotate_h = "convert #{gmtNAME_h}.png -rotate #{rotate_degree} #{gmtNAME_h}_rotate.png"

			############## finish hi-res   ###################################
			###### plot netcdf datasets, transpare: -Q ####################
			step2_1 = "gmt grdimage #{below_NC} #{gmtRR} -Ba5f2 -BNWsE+t'#{method_full_name} Probability Forecast' #{gmtJJ} -Q -C#{below_CPT} -K -V #{gmt_rotate} > #{gmtNAME}.ps"
			step2_2 = "gmt grdimage #{avg_NC} #{gmtRR} -Ba5f2 -BnWsE #{gmtJJ} -Q -C#{avg_CPT} -K -O -V #{gmt_rotate} >> #{gmtNAME}.ps"
			step2_3 = "gmt grdimage #{above_NC} #{gmtRR} -Ba5f2 -BnWsE #{gmtJJ} -Q -C#{above_CPT} -K -O -V #{gmt_rotate} >> #{gmtNAME}.ps"
			step3 = "gmt pscoast #{gmtRR} #{gmtJJ} -B0 -Df -N1/2p -W1p -Slightblue -A10000 -K -O >> #{gmtNAME}.ps"

			steptxt1 = "echo Hindcast: #{@sdy} to #{@edy} Forecast months: #{@fmonths} #{@ic_year}-#{@ic_month[0..1]} | gmt pstext #{gmtRR} #{gmtJJ} -N -F+cCB -K -O >> #{gmtNAME}.ps"
			#steptxt2 = "echo Forecast months: #{@fmonths} #{@ic_year}-#{@ic_month[0..1]} | gmt pstext #{gmtRR} #{gmtJJ} -N -F+cCB -K -O >> #{gmtNAME}.ps"


			#### plot colar bar ########################
			step4_1 = "gmt psscale -Dx1c/-1c+w3c/0.5c+h -C#{below_CPT} -L -Bx+l#{"Below"} -K -O >> #{gmtNAME}.ps"
			step4_2 = "gmt psscale -Dx5c/-1c+w3c/0.5c+h -C#{avg_CPT} -L -Bx+l#{"Avg"} -K -O >> #{gmtNAME}.ps"
			step4_3 = "gmt psscale -Dx9c/-1c+w3c/0.5c+h -C#{above_CPT} -L -Bx+l#{"Above"} -O >> #{gmtNAME}.ps"
			# output jpg file
			output_pdf = "gmt psconvert #{gmtNAME}.ps -Tf -A"
			output_jpg = "gmt psconvert #{gmtNAME}.ps -Tj -A"
			output_png = "gmt psconvert #{gmtNAME}.ps -Tg -A"

			output_rotate = "convert #{gmtNAME}.png -rotate #{rotate_degree} #{gmtNAME}_rotate.png"
			#################################################
			system step2_1
			system step2_2
			system step2_3
			system step3
			system steptxt1
			#system steptxt2
			system step4_1
			system step4_2
			system step4_3
			system output_png
			system output_rotate
			############# exec for hi-res ##############################
=begin
		    system step1_h
		    system step2_1_h
		    system step2_2_h
		    system step2_3_h
		    system step3_h
		    system step4_1_h
		    system step4_2_h
		    system step4_3_h
		    system output_png_h
		    system output_rotate_h
=end
			######### grid only plot for leaflet map ################
			cp1 = "gmt grdimage #{below_NC} #{gmtRR} -C#{below_CPT} #{gmt_rotate} -Q -JM5i -I+ -K > cp_#{gmtNAME}.ps"
			cp2 = "gmt grdimage #{avg_NC} #{gmtRR} -C#{avg_CPT} #{gmt_rotate} -Q -JM5i -I+ -K -O >> cp_#{gmtNAME}.ps"
			cp3 = "gmt grdimage #{above_NC} #{gmtRR} -C#{above_CPT} #{gmt_rotate} -Q -JM5i -I+ -K -O >> cp_#{gmtNAME}.ps"
			## -E + ISO country code plot country boundary(-ENP+g#CD5C5C), -B = board, box
			cp4 = "gmt pscoast #{gmtRR} #{gmtJJ} #{gmt_rotate} -B0 -Df -N1/1p -W1p -Slightblue -A10000 -O >> cp_#{gmtNAME}.ps"
			cp5 = "gmt psconvert cp_#{gmtNAME}.ps -Tg -A"

			cp6 = "convert cp_#{gmtNAME}.png -rotate #{rotate_degree} cp_#{gmtNAME}_rotate.png"

			system cp1 
			system cp2 
			system cp3 
			system cp4 
			system cp5 
			system cp6 

			############# finish GMT plot ###############################################
			#
			#	@final_png ="#{gmtNAME}.png" 
			#	@final_png_h ="#{gmtNAME_h}.png" 
			#	@cp_png ="cp_#{gmtNAME}.png" 

		    end #Dir.chdir(output_dir) do

		end	# output[:prec].each do |params_prob|

	    end #@all_output.each do |output| 


	    @fin_output = []	

	    @methods.each do |method| 

		if method == "MME1" then method_full_name = "Simple Mean Method (SMM)" end
		if method == "MME2" then method_full_name = "Weighted Average Method (WAM)" end
		if method == "PCR" then method_full_name = "Principal components regression (PCR)" end

		### images on the leaflet map
		cp_file = Dir["#{output_dir}/cp_#{method}_*_rotate.png"].sort 

		### final probabilistic forecast images 
		#prob_fin = Dir["#{output_dir}/#{method}_PROB_FINAL.png"].sort 

		@fin_output << {method: method, cp: cp_file, method_full_name: method_full_name }	

	    end #@methods.each do |method| 

	    e_total_time = Time.new

	    @total_analysis_time = (e_total_time - s_total_time).round(2)


	end

    end


    def probpoint

	@cdo = Cdo.new()

	@cdo.debug = true

	@lon = params[:lon].to_i

	@lat = params[:lat].to_i

	@info = params[:info]

	@method = params[:method]

	@below = Dir["#{@info}/#{@method}_below_prob.nc"][0] 
	@avg = Dir["#{@info}/#{@method}_avg_prob.nc"][0]
	@above = Dir["#{@info}/#{@method}_above_prob.nc"][0]



	@below_point = `cdo outputtab,value -remapnn,lon=#{@lon}_lat=#{@lat} #{@below}` 
	@avg_point =  `cdo outputtab,value -remapnn,lon=#{@lon}_lat=#{@lat} #{@avg}` 
	@above_point = `cdo outputtab,value -remapnn,lon=#{@lon}_lat=#{@lat} #{@above}` 


    end

    def anomaly

	@download_dir = params[:dir]

	@fin_output = params[:fin_output]

	@fmonths = params[:fmonths]

	@page_title = "Anomaly (mm/day) of #{@fmonths}"

	##### for GMT plot #####
	#@anom_files = Dir["/home/focus/www/focus/public/#{@download_dir}/*_anom_prec_raw_rotate.png"].sort 

	##### for GrADS plot #####
	@anom_files = Dir["/home/focus/www/focus/public/#{@download_dir}/*_anom_prec_gr.png"].sort 

	@anom_nc_files = Dir["/home/focus/www/focus/public/#{@download_dir}/*_anom_prec.nc"].sort 

    end



    def departure 

	@download_dir = params[:dir]

	@fin_output = params[:fin_output]

	@fmonths = params[:fmonths]

	@page_title = "Departure of #{@fmonths}"

	##### for GMT plot #####
	#@dep_files = Dir["/home/focus/www/focus/public/#{@download_dir}/*_dep_prec_raw_rotate.png"].sort 

	##### for GrADS plot #####
	@dep_files = Dir["/home/focus/www/focus/public/#{@download_dir}/*_dep_prec_gr.png"].sort 

	@dep_nc_files = Dir["/home/focus/www/focus/public/#{@download_dir}/*_dep_prec.nc"].sort 

    end

    def corr 

	@download_dir = params[:dir]

	@fin_output = params[:fin_output]

	@fmonths = params[:fmonths]

	@page_title = "Correlation of #{@fmonths}"

	##### for GMT plot #####
	#@corr_files = Dir["/home/focus/www/focus/public/#{@download_dir}/*_corr_prec_raw_rotate.png"].sort 

	##### for GrADS plot #####
	@corr_files = Dir["/home/focus/www/focus/public/#{@download_dir}/*_corr_prec_gr.png"].sort 

	@corr_nc_files = Dir["/home/focus/www/focus/public/#{@download_dir}/*_corr_prec.nc"].sort 
    end


    def climatology 

	@download_dir = params[:dir]

	@page_title = "Climatology"

	@fmonths = params[:fmonths]

	@models = params[:models]

	@clim_data = []

	@models.each do |m|

	    png = "#{@download_dir}/#{m}_climatology.nc.png" 

	    nc = "#{@download_dir}/#{m}_climatology_dl.nc" 

	    @clim_data << {model: m, png: png, nc: nc} 

	end #@models.each do |m|


	@obs_data = []

	obs_png = "#{@download_dir}/obs_climatology.nc.png" 

	obs_nc = "#{@download_dir}/obs_climatology.nc" 

	@obs_data << {model: "Observation" , png: obs_png, nc: obs_nc} 




    end



    def sd 

	@download_dir = params[:dir]

	@page_title = "Standard Deviation"

	@fmonths = params[:fmonths]

	@models = params[:models]

	@sd_data = []

	@models.each do |m|

	    png = "#{@download_dir}/#{m}_sd.nc.png" 

	    nc = "#{@download_dir}/#{m}_sd.nc" 

	    @sd_data << {model: m, png: png, nc: nc} 

	end #@models.each do |m|

	@obs_data = []

	obs_png = "#{@download_dir}/obs_sd.nc.png" 

	obs_nc = "#{@download_dir}/obs_sd.nc" 

	@obs_data << {model: "Observation" , png: obs_png, nc: obs_nc} 

    end



    def rmse 

	@download_dir = params[:dir]

	@page_title = "Root Mean Square Error"

	@models = params[:models]

	@fmonths = params[:fmonths]

	@rmse_data = []

	@models.each do |m|

	    png = "#{@download_dir}/#{m}_rmse.nc.png" 

	    nc = "#{@download_dir}/#{m}_rmse.nc" 

	    @rmse_data << {model: m, png: png, nc: nc} 

	end #@models.each do |m|

    end

    def acc 

	@download_dir = params[:dir]

	@page_title = "Anomaly Correlation Coefficient"

	@models = params[:models]

	@fmonths = params[:fmonths]

	@acc_data = []

	@models.each do |m|

	    png = "#{@download_dir}/#{m}_acc.nc.png" 

	    nc = "#{@download_dir}/#{m}_acc.nc" 

	    @acc_data << {model: m, png: png, nc: nc} 

	end #@models.each do |m|

    end



end # class
