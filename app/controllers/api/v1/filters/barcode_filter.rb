# See README.md for copyright details

class Api::V1::Filters::BarcodeFilter
  def self.filter(params)
    { barcode: params[:barcode]}
  end
end