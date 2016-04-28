# See README.md for copyright details

class Api::V1::LabwareTypesController < Api::V1::ApplicationController
  before_action :set_labware_type, only: [:show]

  # GET /labware_types
  def index
    @labware_types = LabwareType.all

    render json: @labware_types, include: included_relations_to_render
  end

  # GET /labware_types/1
  def show
    render json: @labware_type, include: included_relations_to_render
  end

  # # POST /labware_types
  # def create
  #   @labware_type = LabwareType.new(labware_type_params)

  #   if @labware_type.save
  #     render json: @labware_type, status: :created, location: @labware_type
  #   else
  #     render json: @labware_type.errors, status: :unprocessable_entity
  #   end
  # end

  # # PATCH/PUT /labware_types/1
  # def update
  #   if @labware_type.update(labware_type_params)
  #     render json: @labware_type
  #   else
  #     render json: @labware_type.errors, status: :unprocessable_entity
  #   end
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_labware_type
      @labware_type = LabwareType.find(params[:id])
    end

    def included_relations_to_render
      [:layout]
    end

    # # Only allow a trusted parameter "white list" through.
    # def labware_type_params
    #   params.require(:labware_type).permit(:name)
    # end
end
