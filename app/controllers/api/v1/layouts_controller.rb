# See README.md for copyright details

class Api::V1::LayoutsController < Api::V1::ApplicationController
  before_action :set_layout, only: [:show]

  # GET /layouts
  def index
    @layouts = Layout.all

    render json: @layouts, include: included_relations_to_render
  end

  # GET /layouts/1
  def show
    render json: @layout, include: included_relations_to_render
  end

  # # POST /layouts
  # def create
  #   @layout = Layout.new(layout_params)

  #   if @layout.save
  #     render json: @layout, status: :created, location: @layout
  #   else
  #     render json: @layout.errors, status: :unprocessable_entity
  #   end
  # end

  # # PATCH/PUT /layouts/1
  # def update
  #   if @layout.update(layout_params)
  #     render json: @layout
  #   else
  #     render json: @layout.errors, status: :unprocessable_entity
  #   end
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_layout
      @layout = Layout.find(params[:id])
    end

    def included_relations_to_render
      [:locations]
    end

    # # Only allow a trusted parameter "white list" through.
    # def layout_params
    #   params.require(:layout).permit(:name)
    # end
end
