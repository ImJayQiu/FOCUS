class WikiPagesController < ApplicationController

    layout "crud"

  before_action :set_wiki_page, only: [:show, :edit, :update, :destroy]

  # GET /wiki_pages
  # GET /wiki_pages.json
  def index
    @wiki_pages = WikiPage.all
  end

  def wikifocus 
    @wiki_pages = WikiPage.all
  end


  # GET /wiki_pages/1
  # GET /wiki_pages/1.json
  def show
  end

  # GET /wiki_pages/new
  def new
    @wiki_page = WikiPage.new
  end

  # GET /wiki_pages/1/edit
  def edit
  end

  # POST /wiki_pages
  # POST /wiki_pages.json
  def create
    @wiki_page = WikiPage.new(wiki_page_params)

    respond_to do |format|
      if @wiki_page.save
        format.html { redirect_to @wiki_page, notice: 'Wiki page was successfully created.' }
        format.json { render :show, status: :created, location: @wiki_page }
      else
        format.html { render :new }
        format.json { render json: @wiki_page.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /wiki_pages/1
  # PATCH/PUT /wiki_pages/1.json
  def update
    respond_to do |format|
      if @wiki_page.update(wiki_page_params)
        format.html { redirect_to @wiki_page, notice: 'Wiki page was successfully updated.' }
        format.json { render :show, status: :ok, location: @wiki_page }
      else
        format.html { render :edit }
        format.json { render json: @wiki_page.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /wiki_pages/1
  # DELETE /wiki_pages/1.json
  def destroy
    @wiki_page.destroy
    respond_to do |format|
      format.html { redirect_to wiki_pages_url, notice: 'Wiki page was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_wiki_page
      @wiki_page = WikiPage.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def wiki_page_params
      params.require(:wiki_page).permit(:chapter, :heading1, :heading2, :heading3, :title, :content, :image1, :image2)
    end
end
