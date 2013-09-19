Quantum::App.controllers :circuits do
  before do
    c_id = params[:c_id]
    @c_id = c_id.nil? ? nil : c_id.to_i
    v_id = params[:v_id]
    @v_id = v_id.nil? ? nil : v_id.to_i
  end

  get :show, :map => '/circuits(/:c_id)(/:v_id)', :provides => [:html, :json] do
    case content_type
    when :json then
      if @v_id.nil?
        @circuit = Circuit.new.ensure_values
      else
        @circuit = Circuit.find_or_create_by_c_id_and_v_id(@c_id, @v_id).ensure_values
      end
      render 'circuits/show.rabl'
    else
      render 'circuits/show.erb'
    end
  end

  put :update, :map => '/circuits(/:c_id)(/:v_id)', :provides => [:json] do
    @c_id = Circuit.new_c_id if @c_id.nil?
    if @v_id.nil?
      @circuit = Circuit.new
      @circuit.c_id = @c_id
    else
      @circuit = Circuit.find_by_c_id_and_v_id @c_id, @v_id
      # Create a new record based on old one
      @circuit._id = BSON::ObjectId.new
    end

    # Set the version id to one higher
    @circuit.v_id = Circuit.new_v_id(@c_id)

    # Update it's attributes
    # TODO Only allow certain attributes to be set
    @circuit.update_attributes! JSON.parse(params["circuit"])
    @circuit.save

    {
      'status' => 'successful',
      'url' => url_for(:circuits, :show, :c_id => @c_id, :v_id => @circuit.v_id)
    }.to_json
  end

  post :run, :map => '/circuits/run', :provides => [:json] do
    circuit = JSON.parse params["circuit"]

    @circuit = Circuit.new
    @circuit.operators = circuit["operators"]
    @circuit.lines = circuit["lines"]

    @results = @circuit.run.map do |result|
      Hash[result.map { |k, v| [k.underscore, v] }]
    end

    {'results' => @results}.to_json
  end
end
