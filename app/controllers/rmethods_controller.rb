class RmethodsController < ApplicationController
  before_action :set_rmethod, only: [:show, :edit, :update, :destroy]

  # GET /rmethods
  # GET /rmethods.json
  def index
    @rmethods = Rmethod.all
  end

  # GET /rmethods/1
  # GET /rmethods/1.json
  def show
  end

  # GET /rmethods/new
  def new
    @rmethod = Rmethod.new
  end

  # GET /rmethods/1/edit
  def edit
  end

  # POST /rmethods
  # POST /rmethods.json
  def create
    @rmethod = Rmethod.new(rmethod_params)

    respond_to do |format|
      if @rmethod.save
        format.html { redirect_to @rmethod, notice: 'Rmethod was successfully created.' }
        format.json { render :show, status: :created, location: @rmethod }
      else
        format.html { render :new }
        format.json { render json: @rmethod.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rmethods/1
  # PATCH/PUT /rmethods/1.json
  def update
    respond_to do |format|
      if @rmethod.update(rmethod_params)
        format.html { redirect_to @rmethod, notice: 'Rmethod was successfully updated.' }
        format.json { render :show, status: :ok, location: @rmethod }
      else
        format.html { render :edit }
        format.json { render json: @rmethod.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rmethods/1
  # DELETE /rmethods/1.json
  def destroy
    @rmethod.destroy
    respond_to do |format|
      format.html { redirect_to rmethods_url, notice: 'Rmethod was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_rmethod
      @rmethod = Rmethod.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def rmethod_params
      params.require(:rmethod).permit(:name, :fname, :remark)
    end
end
