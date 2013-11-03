Quantum::App.controllers :operators do
  get :index, :map => '/operators(/:c_id)', :provides => :json, :cache => true do
    expires_in 15
    cache_key request.path_info + "?" + {"c_id" => params[:c_id], "uid" => session[:uid]}.to_param

    # Default operators
    operators_default = Operator.find_all_by_default true

    # Operators of current circuits
    operators_circuit = []
    unless params[:c_id].nil?
      operators_circuit = Circuit.find_all_by_c_id(params[:c_id].to_i).reduce([]) do |memo, circuit|
        memo + circuit.operators
          .map { |o| o["operator_id"] }
          .uniq
          .map { |oid| Operator.find oid }
      end
    end
 
    # Operators of current user
    operators_user = []
    operators_user = current_user.operators if signed_in?

    @operators = (operators_default + operators_user + operators_circuit).uniq
    render 'operators/index.rabl'
  end

  post :new, :map => '/operators', :provides => :json do
    require_sign_in

    operator = Operator.create JSON.parse(params[:operator])
    operator.uid = current_user.uid
    operator.default = false
    operator.save

    return {:id => operator._id}.to_json
  end

  get :show, :map => '/operators/details/:id', :provides => :json do
    @operator = Operator.find params[:id]
    jmatrix = cache("matrix_for_operator_#{params[:id]}", :expires_in => 3600) do
      JSON.generate @operator.latex_matrix, quirks_mode: true
    end
    @matrix = JSON.parse(jmatrix, quirks_mode: true)

    render 'operators/show.rabl'
  end
end
