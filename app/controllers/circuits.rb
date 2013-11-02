Quantum::App.controllers :circuits do
  before do
    # Get c_id and v_id from url parameters, setting nil if they don't exist
    c_id = params[:c_id]
    @c_id = (c_id.nil? or c_id.empty?) ? nil : c_id.to_i
    v_id = params[:v_id]
    @v_id = (v_id.nil? or v_id.empty?) ? nil : v_id.to_i
  end

  # List of circuits
  get :index, :map => '/my_circuits', :provides => :html do
    redirect_to url_for(:circuits, :show) unless signed_in?

    @circuits = current_user.grouped_circuits(5)
    render 'circuits/index.erb'
  end

  get :show, :map => '/circuits(/:c_id)(/:v_id)', :provides => [:html, :json] do
    case content_type
    when :json then
      # Find circuit, creating one if not a valid v_id
      if @v_id.nil?
        @circuit = Circuit.new.ensure_values
      else
        @circuit = Circuit.find_or_create_by_c_id_and_v_id(@c_id, @v_id).ensure_values
        halt 403 unless (signed_in? and @circuit.created_by?(current_user)) or @circuit.world_readable
      end
      # Work out the url for each circuit iteration
      @iterations = @circuit.iterations.map do |i|
        i[:url] = url_for(:circuits, :show, :c_id => i[:c_id], :v_id => i[:v_id])
        i
      end
      @iterations.sort_by! { |c| c[:v_id] }
      @can_change_settings = signed_in? ? @circuit.created_by?(current_user) : false
      render 'circuits/show.rabl'
    else
      # JS circuit viewer/editor
      render 'circuits/show.erb'
    end
  end

  # Change name of circuit
  post :change_name, :map => '/circuits/:c_id/:v_id/name', :provides => [:json] do
    require_sign_in

    @circuit = Circuit.find_by_c_id_and_v_id @c_id, @v_id
    halt 403 unless @circuit.created_by?(current_user)
    halt 400 unless params["name"] == "circuitName"

    @circuit.change_name params["value"]

    {'status' => 'successful'}.to_json
  end

  # Change world readability/editability of circuit
  post :change_switches, :map => '/circuits/:c_id/:v_id/switches', :provides => [:json] do
    require_sign_in

    @circuit = Circuit.find_by_c_id_and_v_id @c_id, @v_id
    halt 403 unless @circuit.created_by?(current_user)

    readable = params["readable"]
    editable = params["editable"]
    @circuit.change_world_readable readable unless readable.nil?
    @circuit.change_world_editable editable unless editable.nil?

    {'status' => 'successful'}.to_json
  end

  # Update/create a circuit
  put :update, :map => '/circuits(/:c_id)(/:v_id)', :provides => [:json] do
    require_sign_in

    # Find new circuit_id 
    @c_id = Circuit.new_c_id if @c_id.nil?
    # Create new circuit if one doesn't exist yet
    if @v_id.nil?
      @circuit = Circuit.new
      @circuit.c_id = @c_id
    else
      @circuit = Circuit.find_by_c_id_and_v_id @c_id, @v_id
      halt 403 unless (signed_in? and @circuit.created_by?(current_user)) or @circuit.world_editable
      # Create a new record based on old one
      @circuit._id = BSON::ObjectId.new
    end

    # Set user id to current user's id
    @circuit.uid = current_user.uid

    # Set the version id to one higher
    @circuit.v_id = Circuit.new_v_id(@c_id)

    # Update it's attributes
    circuit = JSON.parse params["circuit"]
    %w{operators lines initial_state}.each { |k| @circuit[k] = circuit[k] }
    @circuit.save
    
    if @circuit.created_by? current_user
      @circuit.change_name circuit['name']
      @circuit.change_world_readable circuit['world_readable']
      @circuit.change_world_editable circuit['world_editable']
    end

    {
      'status' => 'successful',
      'url' => url_for(:circuits, :show, :c_id => @c_id, :v_id => @circuit.v_id)
    }.to_json
  end

  # Run the circuit data posted
  post :run, :map => '/circuits/run', :provides => [:json] do
    circuit = JSON.parse(params["circuit"])

    # Create new circuit from the posted data, but don't save it
    @circuit = Circuit.new
    @circuit.operators = circuit["operators"]
    @circuit.lines = circuit["lines"]
    @circuit.initial_state = circuit["initial_state"]

    @results = @circuit.run

    @results.to_json
  end

  # Run an already-saved circuit
  get :run, :map => '/circuits/:c_id/:v_id/run', :provides => [:json] do
    @circuit = Circuit.find_by_c_id_and_v_id @c_id, @v_id
    halt 403 unless (signed_in? and @circuit.created_by?(current_user)) or @circuit.world_readable
    @results = @circuit.run

    @results.to_json
  end
end
