# See README.md for copyright details

class Api::V1::Filters::ExternalIdFilter
  def self.filter(params)
    { external_id: params[:external_id]}
  end
end