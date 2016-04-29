# See README.md for copyright details

class Api::V1::LabwaresController < Api::V1::ApplicationController
  before_action :set_labware, only: [:show, :create, :update]

  # GET /labwares
  def index
    @labwares = Labware.all

    render json: @labwares, include: included_relations_to_render
  end

  # GET /labwares/1
  def show
    render json: @labware, include: included_relations_to_render
  end

  # POST /labwares
  def create
    @labware = Labware.new(labware_params)

    if @labware.save
      render json: @labware, status: :created, include: included_relations_to_render
    else
      render json: @labware.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /labwares/1
  def update
    if @labware.update(labware_params)
      render json: @labware, include: included_relations_to_render
    else
      render json: @labware.errors, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_labware
    @labware = Labware.find_by(uuid: params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def labware_params
    params = (labware_json_params[:attributes] or {}).merge(uuid: labware_json_params[:id]).delete_if { |k, v| v.nil? }

    if labware_json_params[:relationships] and
        labware_json_params[:relationships][:labware_type] and
        labware_json_params[:relationships][:labware_type][:data] and
        labware_json_params[:relationships][:labware_type][:data][:attributes]
      params = params.merge(labware_type: LabwareType.find_by(labware_json_params[:relationships][:labware_type][:data][:attributes]))
    end

    params
  end

  def labware_json_params
    params.require(:data).permit([
                                     :id,
                                     attributes: [:external_id, :barcode, :barcode_prefix, :barcode_info],
                                     relationships: {labware_type: {data: {attributes: [:name]}}}
                                 ])
  end

  def included_relations_to_render
    [:labware_type]
  end
end