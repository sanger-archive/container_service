class LabwareTypesController < ApplicationController
  before_action :set_labware_type, only: [:show, :update, :destroy]

  # GET /labware_types
  def index
    @labware_types = LabwareType.all

    render json: @labware_types
  end

  # GET /labware_types/1
  def show
    render json: @labware_type
  end

  # POST /labware_types
  def create
    @labware_type = LabwareType.new(labware_type_params)

    if @labware_type.save
      render json: @labware_type, status: :created, location: @labware_type
    else
      render json: @labware_type.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /labware_types/1
  def update
    if @labware_type.update(labware_type_params)
      render json: @labware_type
    else
      render json: @labware_type.errors, status: :unprocessable_entity
    end
  end

  # DELETE /labware_types/1
  def destroy
    @labware_type.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_labware_type
      @labware_type = LabwareType.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def labware_type_params
      params.require(:labware_type).permit(:name)
    end
end
