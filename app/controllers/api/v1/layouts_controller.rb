# See README.md for copyright details

class Api::V1::LayoutsController < Api::V1::ApplicationController
  before_action :set_layout, only: [:show]

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_layout
      @layout = Layout.find(params[:id])
    end

    def included_relations_to_render
      [:locations]
    end
end
