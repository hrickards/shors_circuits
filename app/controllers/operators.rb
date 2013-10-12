Quantum::App.controllers :operators do
  get :index, :map => '/operators', :provides => :json do
    @operators = Operator.all
    render 'operators/index.rabl'
  end
end
