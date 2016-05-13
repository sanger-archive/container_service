# See README.md for copyright details

class Api::V1::Filters::BarcodeInfoFilter
  def self.filter(params)
    [ "barcode LIKE :barcode_info", {barcode_info: '%' + params[:barcode_info] + '%'} ]
  end
end