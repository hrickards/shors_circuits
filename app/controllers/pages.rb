Quantum::App.controllers :pages do
  get :home, :map => '/' do
    render 'pages/home'
  end

  get :about, :map => '/about' do
    render 'pages/about'
  end
end
