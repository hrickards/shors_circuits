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
    require_sign_in
    redirect_to url_for(:pages, :home) unless signed_in?

    # Get all of the current user's circuits
    @circuits = current_user.circuits.group_by { |c| c.c_id }.to_a
    # For each circuit, show the last 5 iterations, and find the modified date
    @circuits.map! do |cid, circuits|
      [
        cid,
        circuits.sort_by { |circuit| circuit.v_id }.last(5),
        circuits.map { |circuit| circuit.updated_at }.sort.first
      ]
    end
    # Sort circuits by date, starting with most recent
    @circuits.sort_by! { |cid, circuits, updated_at| updated_at }
    @circuits.reverse!

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
      end
      # Work out the url for each circuit iteration
      @iterations = @circuit.iterations.map do |i|
        i[:url] = url_for(:circuits, :show, :c_id => i[:c_id], :v_id => i[:v_id])
        i
      end
      @iterations.sort_by! { |c| c[:v_id] }
      render 'circuits/show.rabl'
    else
      # JS circuit viewer/editor
      render 'circuits/show.erb'
    end
  end

  # Update/create a circuit
  put :update, :map => '/circuits(/:c_id)(/:v_id)', :provides => [:json] do
    require_sign_in

    # Require a user to be signed in
    redirect_to url_for(:pages, :home) unless signed_in?
    
    # Find new circuit_id 
    @c_id = Circuit.new_c_id if @c_id.nil?
    # Create new circuit if one doesn't exist yet
    if @v_id.nil?
      @circuit = Circuit.new
      @circuit.c_id = @c_id
    else
      @circuit = Circuit.find_by_c_id_and_v_id @c_id, @v_id
      # Create a new record based on old one
      @circuit._id = BSON::ObjectId.new
    end

    # Set user id to current user's id
    @circuit.uid = current_user.uid

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

  # Run the circuit data posted
  post :run, :map => '/circuits/run', :provides => [:json] do
    require_sign_in

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
    require_sign_in

    @circuit = Circuit.find_by_c_id_and_v_id @c_id, @v_id
    @results = @circuit.run

    @results.to_json
  end
end
