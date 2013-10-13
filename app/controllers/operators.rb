Quantum::App.controllers :operators do
  get :index, :map => '/operators', :provides => :json do
    @operators = Operator.all
    render 'operators/index.rabl'
  end

  post :new, :map => '/operators', :provides => :json do
    operator = Operator.create JSON.parse(params[:operator])

    return {:id => operator._id}.to_json
  end
end
