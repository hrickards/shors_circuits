Quantum::App.controllers :latex do
  get :qcircuit, :with => [:code], :provides => [:png, :svg] do
    cache("latex_qcircuit_#{params[:code]}_#{params[:format]}_#{params[:width]}_#{params[:height]}") do
      Latex.qcircuit params[:code], params[:format], params[:width], params[:height]
    end
  end

  get :ket, :with => [:code], :provides => [:png, :svg] do
    cache("latex_ket_#{params[:code]}_#{params[:format]}_#{params[:width]}_#{params[:height]}") do
      Latex.ket params[:code], params[:format], params[:width], params[:height]
    end
  end

  get :math, :with => [:code], :provides => [:png, :svg] do
    cache("latex_math_#{params[:code]}_#{params[:format]}_#{params[:width]}_#{params[:height]}") do
      Latex.math params[:code], params[:format], params[:width], params[:height]
    end
  end
end
