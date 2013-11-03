Quantum::App.controllers :pages do
  get :home, :map => '/' do
    if signed_in?
      @my_circuits = cache("homepage_circuits_for_#{current_uid}") do
        @circuits = current_user.grouped_circuits(5)
        partial 'pages/small_circuits'
      end
    else
      @examples = cache("homepage_examples") do
        partial 'pages/examples'
      end
    end

    render 'pages/home'
  end

  get :about, :map => '/about' do
    render 'pages/about'
  end
end
