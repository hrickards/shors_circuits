POSSIBLE_PROVIDERS = %w{google github open_id}
Quantum::App.helpers do
  def signed_in?
    !session[:uid].nil?
  end

  def current_user
    signed_in? and User.find_by_uid session[:uid]
  end

  def current_uid
    signed_in? and current_user.uid
  end

  def require_sign_in
    unless signed_in?
      flash[:error] = "You need to be signed in to do that!"
      redirect_to url_for(:pages, :home)
    end
  end

  def require_sign_in_with_error
    halt 403 unless signed_in?
  end

  def no_more_new_providers?
    POSSIBLE_PROVIDERS.reject { |prov| user_authenticated_provider? prov }.empty?
  end

  def user_authenticated_provider?(provider)
    return false unless signed_in?
    current_user.authenticated_with? provider
  end
end
