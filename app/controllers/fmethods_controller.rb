class FmethodsController < ApplicationController

    layout "crud"

    before_action :set_fmethod, only: [:show, :edit, :update, :destroy]

    # GET /fmethods
    # GET /fmethods.json
    def index
	@fmethods = Fmethod.all
    end

    # GET /fmethods/1
    # GET /fmethods/1.json
    def show
    end

    # GET /fmethods/new
    def new
	@fmethod = Fmethod.new
    end

    # GET /fmethods/1/edit
    def edit
    end

    # POST /fmethods
    # POST /fmethods.json
    def create
	@fmethod = Fmethod.new(fmethod_params)

	respond_to do |format|
	    if @fmethod.save
		format.html { redirect_to @fmethod, notice: 'Fmethod was successfully created.' }
		format.json { render :show, status: :created, location: @fmethod }
	    else
		format.html { render :new }
		format.json { render json: @fmethod.errors, status: :unprocessable_entity }
	    end
	end
    end

    # PATCH/PUT /fmethods/1
    # PATCH/PUT /fmethods/1.json
    def update
	respond_to do |format|
	    if @fmethod.update(fmethod_params)
		format.html { redirect_to @fmethod, notice: 'Fmethod was successfully updated.' }
		format.json { render :show, status: :ok, location: @fmethod }
	    else
		format.html { render :edit }
		format.json { render json: @fmethod.errors, status: :unprocessable_entity }
	    end
	end
    end

    # DELETE /fmethods/1
    # DELETE /fmethods/1.json
    def destroy
	@fmethod.destroy
	respond_to do |format|
	    format.html { redirect_to fmethods_url, notice: 'Fmethod was successfully destroyed.' }
	    format.json { head :no_content }
	end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_fmethod
	@fmethod = Fmethod.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def fmethod_params
	params.require(:fmethod).permit(:name, :file_name, :remark1, :remark2)
    end
end
