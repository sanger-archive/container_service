# See README.md for copyright details

class Api::V1::Filters::BarcodePrefixFilter
  def self.filter(params)
    [ "barcode LIKE :barcode_prefix", {barcode_prefix: params[:barcode_prefix] + '%'} ]
  end
end