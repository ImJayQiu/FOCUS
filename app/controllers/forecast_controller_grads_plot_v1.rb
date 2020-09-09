require "date"
require "cdo"

class ForecastController < ApplicationController

    layout "home"

    def apidebug1

	@ic_year = params[:ic_year]
	@ic_month = params[:ic_month]
	@models = params[:models]
	@obs_data = params[:obs_data]
	@sdy = params[:sdy]
	@edy = params[:edy]
	@sfm = params[:sfm]
	@efm = params[:efm]
	@user_id = current_user.id
	@method_ids = params[:method_ids]
	@method_all = Fmethod.find(params[:method_ids])
	@methods = @method_all.pluck(:name) 
	@ic_object = params[:ic_object]

	if @ic_object == "Temperture"
	    object_path = "temp"
	elsif @ic_object == "Precipitation"
	    object_path = "prec"
	end



    end # debug

    def result 


	s_total_time = Time.new

	@cdo = Cdo.new()

	@cdo.debug = true

	@ic_object = params[:ic_object]

	if @ic_object == "Temperture"
	    object_path = "temp"
	elsif @ic_object == "Precipitation"
	    object_path = "prec"
	end

	@ic_year = params[:ic_year]
	@ic_month = params[:ic_month]
	@models = params[:models]
	@obs_data = params[:obs_data]
	@sdy = params[:sdy]

	if @obs_data=="ERA5" and  params[:edy].to_i > 2010
	    @edy = "2010" 
	else
	    @edy = params[:edy]
	end

	@sfm = params[:sfm]
	@efm = params[:efm]
	@method_ids = params[:method_ids]
	@method_all = Fmethod.find(params[:method_ids])

	@user_id = current_user.id
	@country_domain = Country.select(:slon,:elon,:slat,:elat).where(name: current_user.country)[0]

	slon = @country_domain.slon
	elon = @country_domain.elon
	slat = @country_domain.slat
	elat = @country_domain.elat

	#slon = params[:s_lon][0].to_i 
	#elon = params[:e_lon][0].to_i 
	#slat = params[:s_lat][0].to_i 
	#elat = params[:e_lat][0].to_i 

	dom_dir = [slon.to_i, elon.to_i, slat.to_i, elat.to_i].join('_')
	######################################################################################
	##### create folder to keep output data ##########################################
	#####################################################################################

	# able to find historical result from this folder

	output_root = "/home/focus/www/focus/public/forecast_output" 

	# final output dir

	@methods = @method_all.pluck(:name) 

	f_dir = "#{@ic_object}_#{@ic_year}_#{@ic_month[0,2]}_#{@models.join('_')}_#{@obs_data}_#{@sdy}_#{@edy}_#{@sfm[0,2]}_#{@efm[0,2]}_#{@methods.join('_')}"

	output_dir = "#{output_root}/#{dom_dir}/#{f_dir}"

	@download_dir = "forecast_output/#{dom_dir}/#{f_dir}/"

	###########################################################################
	########### check if the result is there ############################### 
	###########################################################################

	if Dir.exist?("#{output_dir}")

	    @all_output = []	

	    @methods.each do |method| 

		if method == "MME1" then method_full_name = "Simple Mean Method (SMM)" end
		if method == "MME2" then method_full_name = "Weighted Average Method (WAM)" end
		if method == "PCR" then method_full_name = "Principal components regression (PCR)" end

		nc_file = Dir["#{output_dir}/#{method}_*_*_*.nc"].sort 

		prec_file = Dir["#{output_dir}/#{method}_*_prec.png"].sort 

		prob_file = Dir["#{output_dir}/#{method}_*_prob.png"].sort 

		png_file = Dir["#{output_dir}/#{method}_*.png"].sort 

		jpg_file = Dir["#{output_dir}/#{method}_*.jpg"].sort 

		@all_output << {method: method, nc: nc_file, png: png_file, jpg: jpg_file, prec: prec_file, prob: prob_file, method_full_name: method_full_name}	

	    end 

	    @py_cmd_output = ["0","0","0"] 

	    @plot_time = "0"

	    e_total_time = Time.new

	    @total_analysis_time = (e_total_time - s_total_time).round(2)

	    return

	end

	################### new analysis : create folder #########################

	mkdir_cmd = "mkdir -p #{output_dir}"

	system mkdir_cmd

	if @methods.include? "PCR" 
	    mkdir_pcr = "mkdir -p #{output_dir}/PCR/CFSv2"
	    system(mkdir_pcr) 
	end

	#################################################################################
	#################### copy datasets ##########################################
	##########################################################################

	cdom = "#{slon},#{elon},#{slat},#{elat}"

	################### copy and merge models data ###########################
	##########################################################################


	fin_mods = []
	seldomains = [] # for params.txt file
	pcrmods = []


	@models.each_with_index do |model,i|

	    selmods = [] 

	    mpath = Dataset.select(:dpath).where(name: @models[i])[0].dpath

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

	    ########## merge data of the model ##############################
	    ##########################################################################

	    mmt =  "cdo mergetime #{selmods.join(' ')} #{output_dir}/#{@models[i]}_merge.nc"

	    seldomains << mmt # for params.txt file 

	    system(mmt)

	    ########### cut dataset by using country domain ################
	    ##########################################################################

	    # cdo_models = @cdo.sellonlatbox(cdom, input: "#{output_dir}/#{@models[i]}_merge.nc", output: "#{output_dir}/#{@models[i]}.nc" )

	    seldomain = "cdo sellonlatbox,#{cdom} #{output_dir}/#{@models[i]}_merge.nc #{output_dir}/#{@models[i]}.nc "
	    system(seldomain) 


	    ########## select forecast month ##############################
	    ##########################################################################

	    ########## forecast month ###############

	    if @sfm[0,2].to_i < @efm[0,2].to_i 

		# if start forecast month is 02, end month is 06, then months will be 02,03,04,05,06
		@fm_range = (@sfm[0,2].to_i..@efm[0,2].to_i).to_a 

	    else

		#if start forecast month is 09, end month is 02, then the months will be 09,10,11,12 + 01,02
		@fm_range = (@sfm[0,2].to_i..12).to_a + (1..@efm[0,2].to_i).to_a 

	    end

	    ####### number of forecast month ####################

	    if @efm.to_i < @sfm.to_i

		# if start month is 09, end month is 02, then number of month is 12 - 9 + 2 + 1 = 6 (12 - 9 did not count Dec. in, so plus 1 at then end)
		@fm_gap = 12 - @sfm.to_i + @efm.to_i + 1 

	    else

		@fm_gap = @efm.to_i - @sfm.to_i + 1

	    end

	    ########### initial month to forecast start  month ##################

	    if @ic_month.to_i > @sfm.to_i

		# if initial month is 10, start month is 02 then the lead time index will be 12 - 10 + 2 = 4 (11,12,1,2)
		@lead = 12 - @ic_month.to_i + @sfm.to_i  

	    else

		@lead = @sfm.to_i - @ic_month.to_i 

	    end

	    if @models[i]=="ECMWF"

		@selmon_ecmwf = "cdo selmon,#{@fm_range.join(',')} #{output_dir}/#{@models[i]}.nc #{output_dir}/#{@models[i]}_sellevel.nc" 
		@runmean_ecmwf = "cdo runmean,#{@fm_gap} #{output_dir}/#{@models[i]}_sellevel.nc #{output_dir}/#{@models[i]}_mean.nc" 

		system	@selmon_ecmwf 
		system	@runmean_ecmwf 

	    else
		#### list lead level [0.5,1.5,....,6.5] 
		@lead_level = (0.5..6.5).step(1).to_a 

		### sellevel @lead_level[3,2] from index 3 to index 5
		@sellevel = @lead_level[@lead.to_i, @fm_gap.to_i] 

		@sellevel_data = "cdo sellevel,#{@sellevel.join(',')} #{output_dir}/#{@models[i]}.nc #{output_dir}/#{@models[i]}_sellevel.nc" 
		@vertmean_data = "cdo vertmean #{output_dir}/#{@models[i]}_sellevel.nc #{output_dir}/#{@models[i]}_mean.nc" 

		system @sellevel_data

		system @vertmean_data

	    end

	    fin_mods << "#{output_dir}/#{@models[i]}_mean.nc"

	end #@models.each do |model|

	################ prepare PCR lead time data ####################

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

	################ prepare PCR lead time data ####################



	########### create models merge file ##############

	system "cdo merge #{fin_mods.join(' ')} #{output_dir}/model.nc"

	if @methods.include? "PCR" 
	    pcr_fin_mods = fin_mods.to_a - ["#{output_dir}/CFSv2_mean.nc"]

	    # create pcr input file, must be lower cases, the upper cases will be the final output files
	    system "cdo merge #{pcr_fin_mods.join(' ')} #{output_dir}/pcr_models.nc"
	end

	#for debug
	@pcrmods2 = pcr_fin_mods

	#################################################################
	################## copy and merge obs data ###############################
	##########################################################################

	selobs=[]

	obspath = Dataset.select(:dpath).where(name: @obs_data)[0].dpath

	(@sdy..@edy).to_a.append(@ic_year)each do |year|

	    obfile = "#{obspath}/#{object_path}/#{@ic_month[0,2]}/ob_*_#{year}.nc"

	    selobs << obfile

	end # [@sdy..@edy].each do |year|

	cdo_merge = @cdo.mergetime(input: selobs.join(" ") )

	### if select ERA5 as observation ############### 

	if @obs_data == "ERA5"

	    cdo_sellonlat = @cdo.sellonlatbox(cdom, input: cdo_merge )

	    cdo_final = @cdo.mulc(1000, input: cdo_sellonlat, output: "#{output_dir}/obs.nc", options: '-b f32' )

	else

	    cdo_final = @cdo.sellonlatbox(cdom, input: cdo_merge, output: "#{output_dir}/obs.nc" )

	end

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

	txt.puts "/FOCUS_DATA/CountryShape/#{country_iso.iso}/-#{country_iso.iso}_adm0"

	txt.close

	################################################################
	############ Analysis based on selected methods  ###############
	################################################################

	@method_py = @method_all.pluck(:file_name) 

	@py_cmds = []

	@py_cmd_output = []

	@method_py.each do |py_f| 

	    st = Time.new

	    py_cmd = `time python /FOCUS_DATA/py_methods/#{py_f} #{output_dir.to_s}/` 
	    py_cmd_check = "python /FOCUS_DATA/py_methods/#{py_f} #{output_dir.to_s}/" 
	    @py_cmds << py_cmd_check 

	    et = Time.new

	    cmd_info ={file: py_f, time: (et - st).round(2)}

	    @py_cmd_output << cmd_info

	end

	####################################################	
	####### list final result #################################

	@final_output = []	

	@final_p_output = []

	@methods.each do |method| 

	    all_nc_file = Dir["#{output_dir}/#{method}_*.nc"] 
	    series_nc_file = Dir["#{output_dir}/*_SERIES_*.nc"] 
	    prob_nc_file = Dir["#{output_dir}/#{method}_PROB_FCST_*.nc"] 
	    nc_file = all_nc_file - series_nc_file 

	    @final_output << {method: method, nc_file: nc_file}	
	    @final_p_output << {method: method, nc_file: prob_nc_file}	

	end 

	#####################################################################

	###########################################################################
	############# Generate map from final NC file #############################################
	splot_time = Time.new 

	@final_output.each do |final| # list output of each forecast method

	    method = final[:method] # name of forecast method

	    if method == "MME1" then method_full_name = "Simple Mean Method (SMM)" end
	    if method == "MME2" then method_full_name = "Weighted Average Method (WAM)" end
	    if method == "PCR" then method_full_name = "Principal components regression (PCR)" end

	    final[:nc_file].each do |nc| #list output netcdf of each forecast method

		current_plot_nc = nc.split("/")[-1] # select only nc file name

		@nc_vars = @cdo.showname(input: nc) # list var names 

		nc_ctl = @cdo.gradsdes(input: nc ) # generate control file of netcdf 

		###################################################################

		@nc_vars[0].split(" ").each do |var|
		    if var.split("_")[0]== "anom" then var_full = "Anomaly" end
		    if var.split("_")[0]== "corr" then var_full = "Correlation" end
		    if var.split("_")[0]== "dep" then var_full = "Departure" end
		    if var.split("_")[0]== "above" then var_full = "Above Normal" end
		    if var.split("_")[0]== "avg" then var_full = "Average" end
		    if var.split("_")[0]== "below" then var_full = "Below Normal" end

		    ############################ GrADS plot #############################
		    gs = File.open("#{output_dir}/#{method}_#{var}.gs", "w")
		    gs.puts("reinit")
		    gs.puts("open #{current_plot_nc[0..-4]}.ctl")
		    gs.puts("set grads off")
		    gs.puts("set gxout grfill")
		    gs.puts("set font 1")
		    gs.puts("set strsiz 0.12")
		    #gs.puts("draw string 1.8 0.1 Initial Condition: #{@ic_year}-#{@ic_month} - #{@sdy}/#{@edy} by FOCUS RIMES.INT")
		    gs.puts("set mpdset mres")
		    gs.puts("set mpt 0 15 1 6")
		    gs.puts("set mpt 1 off")
		    gs.puts("set mpt 2 off")
		    gs.puts("d #{var}")
		    gs.puts("/FOCUS_DATA/GRADS_source/xcbar.gs 9 9.3 1.5 7.0 ")
		    gs.puts("draw title #{method_full_name} Forecast - #{var_full}")
		    gs.puts("printim #{method}_#{var}.png png white")
		    gs.puts("quit")
		    gs.close
		    ##############################################################


		    ##############################################################

		    Dir.chdir(output_dir) do
			system "grads -lbc 'exec #{method}_#{var}.gs'"
		    end

		end

	    end   #final[:nc_file].each do |nc|

	end #@final_output.each do |final|


	eplot_time = Time.new 
	@plot_time = (eplot_time - splot_time).round(2)

	####################################################	
	####### list final result #################################

	@all_output = []	

	@methods.each do |method| 

	    if method == "MME1" then method_full_name = "Simple Mean Method (SMM)" end
	    if method == "MME2" then method_full_name = "Weighted Average Method (WAM)" end
	    if method == "PCR" then method_full_name = "Principal components regression (PCR)" end


	    nc_file = Dir["#{output_dir}/#{method}_*_*_*.nc"].sort 

	    prec_file = Dir["#{output_dir}/#{method}_*_prec.png"].sort 
	    prob_file = Dir["#{output_dir}/#{method}_*_prob.png"].sort 

	    @all_output << {method: method, nc: nc_file, prec: prec_file, prob: prob_file, method_full_name: method_full_name}	

	end 

	#####################################################################

	e_total_time = Time.new

	@total_analysis_time = (e_total_time - s_total_time).round(2)


	################################################################
	############ remove unuse datasets #############################
	################################################################

	system "rm #{output_dir}/*_mean.nc"
	system "rm #{output_dir}/*_merge.nc"
	system "rm #{output_dir}/*_lonlat.nc"

    end #result





    def detail

	#country_domain = Country.select(:slon,:elon,:slat,:elat).where(name: current_user.country)[0]

	path = params[:prec].split("/")

	domain = path[7].split("_") 

	slon = domain[0].to_i 
	elon = domain[1].to_i 
	slat = domain[2].to_i
	elat = domain[3].to_i

	@download_dir = path[6..-2].join("/")

	file_name = path[-1] # MME1_dep_prec.png 

	output_dir = path[0..-2].join("/")

	file_info = file_name.split("_") #["MME1", "dep", "prec.png"] 

	method = file_info[0]

	parameters = path[8].split("_") # Precipitation_2020_04_GFDL-A06_GFDL-AER04_GFDL-B01_CFSv2_CanCM4i_CanSIPSv2_NASA-GEOSS2S_COLA-RSMAS-CCSM4_CHIRPS_1982_2018_05_09_MME1_MME2

	obs_name = parameters[12] 

	func = file_info[1]

	if func == "anom" then func_full_name = "Anomaly" end
	if func == "corr" then func_full_name = "Correlation" end
	if func == "dep" then func_full_name = "Departure" end

	var = file_info[2].split(".")[0] # catch "prce" from "prec.png"

	var_full_name = path[8].split("_")[0] 	

	@page_title = "#{var_full_name} forecast of #{method} - #{func_full_name} " 


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
		@img_rotate = "transform:rotate(0deg);"
		# projection type, size = 5 inch
	    else
		gmtROTATE = ""
		@img_rotate = "transform:rotate(90deg);"
	    end

	    # Projection and size 5 inch
	    gmtJJ="-JM5i" 

	    # output ps file name
	    gmtNAME = "FOCUS_#{var_nc_name}" 
	    gmtNAME_raw = "FOCUS_#{var_nc_name}_raw" 

	    # color bar

	    if var_nc_name.split("_").include? "corr" 

		gmtCPT="/FOCUS_DATA/GMT_source/cpt/corr.cpt"
		xscale="-Bx0.2"

	    elsif var_nc_name.split("_").include? "anom" 

		gmtCPT="/FOCUS_DATA/GMT_source/cpt/nogreen.cpt"
		xscale="-Bx5"

	    elsif var_nc_name.split("_").include? "dep" 

		gmtCPT="/FOCUS_DATA/GMT_source/cpt/dep_v2.cpt"
		xscale="-Bx5"

	    end

	    # surface data file
	    gmtGRD="/FOCUS_DATA/GMT_source/World_topo.grd"

	    # netcdf datasets
	    gmtNC = "#{var_nc_name}.gmt"
	    gmtNC_raw = "#{var_nc_name}.nc"
	    gmtTITLE="#{func_full_name}"

	    # create topo.i file, to plot surface data
	    step1 = "gmt grdgradient #{gmtGRD} -A135 -Nt #{gmtRR} -G#{gmtNAME}.i"
	    #step1_raw = "gmt grdgradient #{gmtGRD} -A135 -Nt #{gmtRR} -G#{gmtNAME_raw}.i"

	    step2 = "gmt grdimage #{gmtNC} #{gmtRR} -I#{gmtNAME}.i -Ba2f1g5 -BNWse+t'#{gmtTITLE}' #{gmtJJ} -C#{gmtCPT} -V #{gmtROTATE} -K > #{gmtNAME}.ps"
	    step2_raw = "gmt grdimage #{gmtNC_raw} #{gmtRR} -Ba2f1g5 -BNWse+t'#{gmtTITLE}' #{gmtJJ} -C#{gmtCPT} -V #{gmtROTATE} -K > #{gmtNAME_raw}.ps"

	    step3 = "gmt pscoast #{gmtRR} #{gmtJJ} -B0 -Df -N3/2p -W1p -Slightblue -A10000 -K -O >> #{gmtNAME}.ps"
	    step3_raw = "gmt pscoast #{gmtRR} #{gmtJJ} -B0 -Df -N3/2p -W1p -Slightblue -A10000 -K -O >> #{gmtNAME_raw}.ps"

	    step4 = "gmt psscale -Dx5.5i/0.1i+w10c/0.5c -C#{gmtCPT} -I #{xscale} -By -O >> #{gmtNAME}.ps"
	    step4_raw = "gmt psscale -Dx5.5i/0.1i+w10c/0.5c -C#{gmtCPT} -I #{xscale} -By -O >> #{gmtNAME_raw}.ps"

	    # output jpg file
	    output_pdf = "gmt psconvert #{gmtNAME}.ps -Tf -A"

	    #output_jpg = "convert -density 400 #{gmtNAME}.ps  -resize 25% -quality 92 #{gmtNAME}.jpg "
	    output_jpg = "gmt psconvert #{gmtNAME}.ps -Tj -A"
	    output_jpg_raw = "gmt psconvert #{gmtNAME_raw}.ps -Tj -A"

	    output_png = "gmt psconvert #{gmtNAME}.ps -Tg -A"
	    #################################################
	    system step1
	    #system step1_raw
	    system step2
	    system step2_raw
	    system step3
	    system step3_raw
	    system step4
	    system step4_raw
	    #system output_pdf
	    system output_jpg
	    system output_jpg_raw

	    @final_nc ="#{var_nc_name}.nc" 
	    @final_jpg ="FOCUS_#{var_nc_name}.jpg" 
	    @final_jpg_raw ="FOCUS_#{var_nc_name}_raw.jpg" 

	    resize_jpg = "convert -resize 50% FOCUS_#{var_nc_name}.jpg small_FOCUS_#{var_nc_name}.jpg"
	    resize_jpg_raw = "convert -resize 50% FOCUS_#{var_nc_name}_raw.jpg small_FOCUS_#{var_nc_name}_raw.jpg"
	    system resize_jpg
	    system resize_jpg_raw

	    @small_jpg ="small_FOCUS_#{var_nc_name}.jpg" 
	    @small_jpg_raw ="small_FOCUS_#{var_nc_name}_raw.jpg" 

	end #Dir.chdir(output_dir) do

    end # detail



    def probfore

	@debug = path = params[:prob].split("/")

	domain = path[7].split("_") 

	slon = domain[0].to_i 
	elon = domain[1].to_i 
	slat = domain[2].to_i
	elat = domain[3].to_i

	@download_dir = path[6..-2].join("/")

	file_name = path[-1] # MME1_dep_prec.png 

	output_dir = path[0..-2].join("/")

	file_info = file_name.split("_") #["MME1", "dep", "prec.png"] 

	method = file_info[0]


	if method == "MME1" then method_full_name = "Simple Mean (SMM)" end
	if method == "MME2" then method_full_name = "Weighted Average (WAM)" end
	if method == "PCR" then method_full_name = "PCR" end
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
	    gmtRR="-R#{slon-0.5}/#{elon+0.5}/#{slat-0.5}/#{elat+0.5}" 

	    if (elon - slon).abs <= (elat-slat).abs 
		gmt_rotate = "-P"
		# projection type, size = 5 inch
		@img_rotate = "transform:rotate(0deg);"
	    else
		gmt_rotate = ""
		@img_rotate = "transform:rotate(90deg);"
	    end

	    # Projection and size 5 inch
	    gmtJJ="-JM5i" 

	    # output ps file name
	    gmtNAME = "#{method}_PROB_final" 
	    gmtNAME_h = "#{method}_PROB_final_h" 

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
	    system below_NC_h 
	    system avg_NC_h 
	    system above_NC_h 
	    # surface data file
	    gmtGRD="/FOCUS_DATA/GMT_source/World_topo.grd"


	    ####################### for hi-res map #################################
	    # create topo.i file, to plot surface data
	    step1_h = "gmt grdgradient #{gmtGRD} -A135 -Nt #{gmtRR} -G#{gmtNAME_h}.i"

	    step2_1_h = "gmt grdimage #{below_NC}.nc #{gmtRR} -Ba5f2 -BNWsE+t'#{method_full_name} Probability Forecast' #{gmtJJ} -Q -C#{below_CPT} -K -V #{gmt_rotate} > #{gmtNAME_h}.ps"

	    step2_2_h = "gmt grdimage #{avg_NC}.nc #{gmtRR} -Ba5f2 -BNWsE+t'#{method_full_name} Probability Forecast' #{gmtJJ} -Q -C#{avg_CPT} -K -V #{gmt_rotate} > #{gmtNAME_h}.ps"

	    step2_3_h = "gmt grdimage #{above_NC}.nc #{gmtRR} -Ba5f2 -BNWsE+t'#{method_full_name} Probability Forecast' #{gmtJJ} -Q -C#{above_CPT} -K -V #{gmt_rotate} > #{gmtNAME_h}.ps"

	    step3_h = "gmt pscoast #{gmtRR} #{gmtJJ} -B0 -Df -N3/2p -W1p -Slightblue -A10000 -K -O >> #{gmtNAME_h}.ps"

	    #### plot colar bar for Hi-res ########################
	    step4_1_h = "gmt psscale -Dx1c/-1c+w3c/0.5c+h -C#{below_CPT} -L -Bx+l#{"Below"} -K -O >> #{gmtNAME_h}.ps"

	    step4_2_h = "gmt psscale -Dx5c/-1c+w3c/0.5c+h -C#{avg_CPT} -L -Bx+l#{"Avg"} -K -O >> #{gmtNAME_h}.ps"

	    step4_3_h = "gmt psscale -Dx9c/-1c+w3c/0.5c+h -C#{above_CPT} -L -Bx+l#{"Above"} -O >> #{gmtNAME_h}.ps"

	    # output jpg file
	    output_pdf_h = "gmt psconvert #{gmtNAME_h}.ps -Tf -A"

	    output_jpg_h = "gmt psconvert #{gmtNAME_h}.ps -Tj -A"

	    output_png_h = "gmt psconvert #{gmtNAME_h}.ps -Tg -A"

	    ############## finish hi-res   ###################################

	    ###### plot netcdf datasets, transpare: -Q ####################
	    step2_1 = "gmt grdimage #{below_NC} #{gmtRR} -Ba5f2 -BNWsE+t'#{method_full_name} Probability Forecast' #{gmtJJ} -Q -C#{below_CPT} -K -V #{gmt_rotate} > #{gmtNAME}.ps"
	    step2_2 = "gmt grdimage #{avg_NC} #{gmtRR} -Ba5f2 -BNWsE #{gmtJJ} -Q -C#{avg_CPT} -K -O -V #{gmt_rotate} >> #{gmtNAME}.ps"
	    step2_3 = "gmt grdimage #{above_NC} #{gmtRR} -Ba5f2 -BNWsE #{gmtJJ} -Q -C#{above_CPT} -K -O -V #{gmt_rotate} >> #{gmtNAME}.ps"
	    step3 = "gmt pscoast #{gmtRR} #{gmtJJ} -B0 -Df -N3/2p -W1p -Slightblue -A10000 -K -O >> #{gmtNAME}.ps"
	    #### plot colar bar ########################
	    step4_1 = "gmt psscale -Dx1c/-1c+w3c/0.5c+h -C#{below_CPT} -L -Bx+l#{"Below"} -K -O >> #{gmtNAME}.ps"
	    step4_2 = "gmt psscale -Dx5c/-1c+w3c/0.5c+h -C#{avg_CPT} -L -Bx+l#{"Avg"} -K -O >> #{gmtNAME}.ps"
	    step4_3 = "gmt psscale -Dx9c/-1c+w3c/0.5c+h -C#{above_CPT} -L -Bx+l#{"Above"} -O >> #{gmtNAME}.ps"
	    # output jpg file
	    output_pdf = "gmt psconvert #{gmtNAME}.ps -Tf -A"
	    output_jpg = "gmt psconvert #{gmtNAME}.ps -Tj -A"
	    output_png = "gmt psconvert #{gmtNAME}.ps -Tg -A"
	    #################################################
	    system step2_1
	    system step2_2
	    system step2_3
	    system step3
	    system step4_1
	    system step4_2
	    system step4_3
	    system output_jpg
	    ############# exec for hi-res ##############################
	    system step1_h
	    system step2_1_h
	    system step2_2_h
	    system step2_3_h
	    system step3_h
	    system step4_1_h
	    system step4_2_h
	    system step4_3_h
	    system output_jpg_h

	    ############# finish GMT plot ###############################################
	    #

	    @final_jpg ="#{gmtNAME}.jpg" 
	    @final_jpg_h ="#{gmtNAME_h}.jpg" 

	end #Dir.chdir(output_dir) do

    end # def probfore



    def apidebug2 

	@cdo = Cdo.new()

	@cdo.debug = true

	object_path = params[:ic_obj]

	@models = params[:models]
	@obs_data = params[:obs]
	@sdy = params[:sdy]

	if @obs_data=="ERA5" and  params[:edy].to_i > 2010
	    @edy = "2010" 
	else
	    @edy = params[:edy]
	end

	slon = params[:slon][0].to_i 
	elon = params[:elon][0].to_i 
	slat = params[:slat][0].to_i 
	elat = params[:elat][0].to_i 

	######################################################################################
	##### create folder to keep output data ##########################################
	#####################################################################################

	# able to find historical result from this folder

	output_root = "/home/focus/www/focus/public/api_output" 

	dom_dir = [slon.to_i, elon.to_i, slat.to_i, elat.to_i].join('_')

	# final output dir

	f_dir = "#{object_path}_#{@models.join('_')}_#{@obs_data}_#{@sdy}_#{@edy}"

	output_dir = "#{output_root}/#{dom_dir}/#{f_dir}"

	@download_dir = "forecast_output/#{dom_dir}/#{f_dir}/"

	mkdir_cmd = "mkdir -p #{output_dir}"

	fin_mods = []
	seldomains = [] # for params.txt file
	pcrmods = []


	@models.each_with_index do |model,i|

	    selmods = [] 

	    mpath = Dataset.select(:dpath).where(name: @models[i])[0].dpath

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
	end

	########## merge data of the model ##############################
	##########################################################################

	mmt =  "cdo mergetime #{selmods.join(' ')} #{output_dir}/#{@models[i]}_merge.nc"

	seldomains << mmt # for params.txt file 

	system(mmt)

	########### cut dataset by using country domain ################
	##########################################################################

	# cdo_models = @cdo.sellonlatbox(cdom, input: "#{output_dir}/#{@models[i]}_merge.nc", output: "#{output_dir}/#{@models[i]}.nc" )

	seldomain = "cdo sellonlatbox,#{cdom} #{output_dir}/#{@models[i]}_merge.nc #{output_dir}/#{@models[i]}.nc "
	final_cmd = system(seldomain) 

	respond_to do |format|
	    if final_cmd == true
		format.json { render json: output_dir, status: :unprocessable_entity }
	    end
	end


    end #def apidebug2 




end # class
