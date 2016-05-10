# See README.md for copyright details

class Api::V1::ApplicationController < ActionController::API

  # GET /{plural_resource_name}
  def index
    plural_resource_name = "@#{resource_name.pluralize}"
    resources = resource_class.where(query_params)
                              .page(page_params[:page])
                              .per(page_params[:page_size])

    instance_variable_set(plural_resource_name, resources)
    resource = instance_variable_get(plural_resource_name)
    render json: resource, include: included_relations_to_render
  end

  # GET /{plural_resource_name}/{id|uuid}
  def show
    render json: get_resource, include: included_relations_to_render
  end

  private

  # Returns the resource from the created instance variable
  # @return [Object]
  def get_resource
    instance_variable_get("@#{resource_name}")
  end

  def included_relations_to_render
    []
  end

  # Returns the allowed parameters for searching
  # Override this method in each API controller
  # to permit additional parameters to search on
  # @return [Hash]
  def query_params
    {}
  end

  def query_sort
    {}
  end

  # Returns the allowed parameters for pagination
  # @return [Hash]
  def page_params
    params.permit(:page, :page_size)
  end

  # The resource class based on the controller
  # @return [Class]
  def resource_class
    @resource_class ||= resource_name.classify.constantize
  end

  # The singular name for the resource class based on the controller
  # @return [String]
  def resource_name
    @resource_name ||= self.controller_name.singularize
  end
end
