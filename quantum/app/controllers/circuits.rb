Quantum::App.controllers :circuits do
  before do
    @c_id = params[:c_id].to_i
    @v_id = params[:v_id].to_i
  end

  get :show, :map => '', :with => [:c_id, :v_id], :provides => [:html, :json] do
    case content_type
    when :json then
      @circuit = Circuit.find_or_create_by_c_id_and_v_id(@c_id, @v_id).ensure_values
      render 'circuits/show.rabl'
    else
      render 'circuits/show.erb'
    end
  end

  put :update, :map => '', :with => [:c_id, :v_id], :provides => [:json] do
    @circuit = Circuit.find_by_c_id_and_v_id @c_id, @v_id
    @circuit.update_attributes! JSON.parse(params["circuit"])
    @circuit.save

    {'status' => 'successful'}.to_json
  end

  get :run, :map => '/circuits/:c_id/:v_id/run', :provides => [:json] do
    @circuit = Circuit.find_by_c_id_and_v_id @c_id, @v_id
    @results = @circuit.run.map do |result|
      Hash[result.map { |k, v| [k.underscore, v] }]
    end

    {'results' => @results}.to_json
  end
end
