Quantum::App.controllers :pages do
  get :home, :map => '/' do
    @circuits = current_user.circuits.reverse[0...5] if signed_in?

    render 'pages/home'
  end

  get :about, :map => '/about' do
    render 'pages/about'
  end
end
