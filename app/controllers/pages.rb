Quantum::App.controllers :pages do
  get :home, :map => '/' do
    if signed_in?
      @circuits = current_user.grouped_circuits(5)
    end

    render 'pages/home'
  end

  get :about, :map => '/about' do
    render 'pages/about'
  end
end
