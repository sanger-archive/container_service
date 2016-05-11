# See README.md for copyright details

class Api::V1::Filters::LabwareBarcodeFilter
  def self.filter(params)
    { barcode: params[:barcode]}
  end
end