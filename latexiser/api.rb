require_relative 'latexiser'
require 'sinatra'

set :port, 4568

get '/qcircuit/:code.:format' do
  content_type mime_type_from_format(params[:format])
  Latexiser.qcircuit(params[:code], params[:format], params[:width], params[:height])
end

def mime_type_from_format(format)
  return 'image/png' if format == 'png'
  return 'image/svg+xml'
end
