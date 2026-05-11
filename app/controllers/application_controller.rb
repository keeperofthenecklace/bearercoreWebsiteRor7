class ApplicationController < ActionController::Base
  helper_method :central_bank_authenticated?

  private

  def central_bank_authenticated?
    session[:central_bank_authenticated] == true
  end

  def require_central_bank_access
    unless central_bank_authenticated?
      session[:central_bank_return_to] = request.fullpath
      redirect_to central_bank_login_path, alert: "Institutional access required."
    end
  end
end
