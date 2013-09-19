Quantum::App.controllers :latex do
  get :qcircuit, :with => [:code], :provides => [:png, :svg] do
    Latex.qcircuit params[:code], params[:format], params[:width], params[:height]
  end

  get :ket, :with => [:code], :provides => [:png, :svg] do
    Latex.ket params[:code], params[:format], params[:width], params[:height]
  end

  get :math, :with => [:code], :provides => [:png, :svg] do
    Latex.math params[:code], params[:format], params[:width], params[:height]
  end
end
