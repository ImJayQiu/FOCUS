require "date"
require "cdo"

class ForecastController < ApplicationController

    layout "home"

    def debug

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

    end

    def result 

	s_total_time = Time.new

	@cdo = Cdo.new()

	@cdo.debug = true

	@ic_year = params[:ic_year]
	@ic_month = params[:ic_month]
	@models = params[:models]
	@obs_data = params[:obs_data]
	@sdy = params[:sdy]
	@edy = params[:edy]
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

	dom_dir = [slon.to_i, elon.to_i, slat.to_i, elat.to_i].join('_')
	######################################################################################
	##### create folder to keep output data ##########################################
	#####################################################################################

	# able to find historical result from this folder

	output_root = "/home/focus/www/focus/public/forecast_output" 

	# final output dir

	@methods = @method_all.pluck(:name) 

	f_dir = "#{@ic_year}_#{@ic_month[0,2]}_#{@models.join('_')}_#{@obs_data}_#{@sdy}_#{@edy}_#{@sfm[0,2]}_#{@efm[0,2]}_#{@methods.join('_')}"

	output_dir = "#{output_root}/#{dom_dir}/#{f_dir}"

	@download_dir = "forecast_output/#{dom_dir}/#{f_dir}/"

	###########################################################################
	########### check if the result is there ############################### 
	###########################################################################
=begin
	if Dir.exist?("#{output_dir}")
	    @historical = "Folder is here, return the results"
	    @nc = `ls #{output_dir}/*.nc`
	    return
	end
=end

	mkdir_cmd = "mkdir -p #{output_dir}"

	system mkdir_cmd

	#################################################################################
	#################### copy datasets ##########################################
	##########################################################################

	cdom = "#{slon},#{elon},#{slat},#{elat}"

	################### copy and merge models data ###########################
	##########################################################################


	fin_mods = []

	@models.each_with_index do |model,i|

	    selmods =[] 

	    mpath = Dataset.select(:dpath).where(name: @models[i])[0].dpath

	    (@sdy..@edy).to_a.append(@ic_year).each do |year|

		mfile = "#{mpath}/#{@ic_month[0,2]}/em_*_#{year}.nc"

		selmods << mfile

	    end # [@sdy..@edy].each do |year|

	    ########## merge data of the model ##############################
	    ##########################################################################

	    system "cdo mergetime #{selmods.join(' ')} #{output_dir}/#{@models[i]}_merge.nc"

	    ########### cut dataset by using country domain ################
	    ##########################################################################

	    cdo_models = @cdo.sellonlatbox(cdom, input: "#{output_dir}/#{@models[i]}_merge.nc", output: "#{output_dir}/#{@models[i]}.nc" )


	    ########## select forecast month ##############################
	    ##########################################################################

	    ########## forecast month ###############

	    if @sfm[0,2].to_i < @efm[0,2].to_i

		@fm_range = (@sfm[0,2].to_i..@efm[0,2].to_i).to_a 

	    else

		@fm_range = (@sfm[0,2].to_i..12).to_a + (1..@efm[0,2].to_i).to_a 

	    end

	    ####### number of forecast month ####################

	    if @efm.to_i < @sfm.to_i

		@fm_gap = 12 - @sfm.to_i + @efm.to_i + 1 

	    else

		@fm_gap = @efm.to_i - @sfm.to_i + 1

	    end

	    ########### initial month to forecast start  month ##################

	    if @ic_month.to_i > @sfm.to_i

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

		@lead_level = (0.5..6.5).step(1).to_a #### level in GFDL data

		@sellevel = @lead_level[@lead.to_i, @fm_gap.to_i] 

		@sellevel_data = "cdo sellevel,#{@sellevel.join(',')} #{output_dir}/#{@models[i]}.nc #{output_dir}/#{@models[i]}_sellevel.nc" 
		@vertmean_data = "cdo vertmean #{output_dir}/#{@models[i]}_sellevel.nc #{output_dir}/#{@models[i]}_mean.nc" 

		system @sellevel_data

		system @vertmean_data

	    end

	    fin_mods << "#{output_dir}/#{@models[i]}_mean.nc"

	end #@models.each do |model|

	########### create models merge file ##############

	system "cdo merge #{fin_mods.join(' ')} #{output_dir}/model.nc"

	#################################################################
	################## copy and merge obs data ###############################
	##########################################################################

	selobs=[]

	obspath = Dataset.select(:dpath).where(name: @obs_data)[0].dpath

	(@sdy..@edy).to_a.each do |year|

	    obfile = "#{obspath}/#{@ic_month[0,2]}/ob_*_#{year}.nc"

	    selobs << obfile

	end # [@sdy..@edy].each do |year|

	cdo_merge = @cdo.mergetime(input: selobs.join(" ") )

	### if select ERA5 as observation ############### 

	if @obs_data = "ERA5"

	    cdo_sellonlat = @cdo.sellonlatbox(cdom, input: cdo_merge )

	    cdo_final = @cdo.mulc(1000, input: cdo_sellonlat, output: "#{output_dir}/obs.nc", options: '-b f32' )

	else

	    cdo_final = @cdo.sellonlatbox(cdom, input: cdo_merge, output: "#{output_dir}/obs.nc" )

	end

	################################################################
	############ remove unuse datasets #############################
	################################################################

	#system "rm #{output_dir}/*_mean.nc"
	#system "rm #{output_dir}/*_merge.nc"
	#system "rm #{output_dir}/*_lonlat.nc"

	############################################################################
	################ copy py scripts ############################################
	##############################################################################

	#cp_py_cmd = "cp /FOCUS_DATA/py_methods/*.py #{output_dir}/"

	#system(cp_py_cmd)


	################## create params txt ###############################
	##########################################################################

	params_path = "#{output_dir}/params.txt"

	country_iso = Country.select(:iso).where(name: current_user.country)[0]

	#	content = "#{@ic_year}\n #{@ic_month}\n #{@models.join(' ')}\n #{@obs_data}\n #{@sdy}/#{@edy}\n #{@sfm}_#{@efm}\n #{@methods}"

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

	@py_cmd_output = []

	@method_py.each do |py_f| 

	    st = Time.new

	    py_cmd = `time python /FOCUS_DATA/py_methods/#{py_f} #{output_dir.to_s}/` 

	    et = Time.new

	    cmd_info ={file: py_f, time: (et - st).round(2)}

	    @py_cmd_output << cmd_info

	end

	####################################################	
	####### list final result #################################

	@final_output = []	

	@methods.each do |method| 

	    nc_file = Dir["#{output_dir}/#{method}_*.nc"] 

	    # output data has vertical dimension #####################
	    vm_ncs=[]

	    nc_file.split(" ") do |method_nc| 
		vm_nc = @cdo.vertmean(input: method_nc, output: "#{method_nc[0..-4]}_vm.nc")	    
		vm_ncs << "#{method_nc[0..-4]}_vm.nc" 
	    end

	    @final_output << {method: method, nc_file: nc_file, vm_nc: vm_ncs}	

	end 
	#####################################################################

	###########################################################################
	############# Generate map from final NC file #############################################
	splot_time = Time.new 

	@final_output.each do |final| # list output of each forecast method

	    method = final[:method] # name of forecast method

	    final[:vm_nc].each do |nc| #list output netcdf of each forecast method

		current_plot_nc = nc.split("/")[-1]

		@nc_vars = @cdo.showname(input: nc) 

		nc_ctl = @cdo.gradsdes(input: nc ) # generate control file of netcdf 
		##############################################

		@nc_vars[0].split(" ").each do |var|

		    gs = File.open("#{output_dir}/#{method}_#{var}.gs", "w")
		    gs.puts("reinit")
		    gs.puts("open #{current_plot_nc[0..-4]}.ctl")
		    gs.puts("set grads off")
		    gs.puts("set gxout shaded")
		    gs.puts("set font 1")
		    gs.puts("set strsiz 0.12")
		    gs.puts("draw string 1.8 0.1 Initial Condition: #{@ic_year}-#{@ic_month} - #{@sdy}/#{@edy} by FOCUS RIMES.INT")
		    gs.puts("set mpdset hires")
		    gs.puts("d #{var}")
		    #grads_gs.puts("cbar.gs")
		    gs.puts("draw title #{method} Forecast of #{current_user.country}")
		    gs.puts("printim #{method}_#{var}_vm.png png white")
		    gs.puts("quit")
		    gs.close

		    Dir.chdir(output_dir) do
			system "grads -lbc 'exec #{method}_#{var}.gs'"
		    end

		end

	    end   #final[:nc_file].each do |nc|

	end #@final_output.each do |final|
	eplot_time = Time.new 
	@plot_time = (eplot_time - splot_time).round(2)

	####################################################	
	Dir.chdir(output_dir) do
	    system "rm *_vm.nc"
	end
	####### list final result #################################

	@all_output = []	

	@methods.each do |method| 

	    nc_file = Dir["#{output_dir}/#{method}_*.nc"] 

	    png_file = Dir["#{output_dir}/#{method}_*.png"] 

	    @all_output << {method: method, nc: nc_file, png: png_file}	

	end 

	#####################################################################

	e_total_time = Time.new

	@total_analysis_time = (e_total_time - s_total_time).round(2)

    end
end
