# See README.md for copyright details

class Api::V1::LabwareTypesController < Api::V1::ApplicationController
  before_action :set_labware_type, only: [:show]

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_labware_type
      @labware_type = LabwareType.find(params[:id])
    end

    def included_relations_to_render
      [:layout, "layout.locations"]
    end
end
