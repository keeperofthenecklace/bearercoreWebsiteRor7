class CentralBankSessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: []

  def new
    redirect_to technical_overview_path if central_bank_authenticated?
  end

  def create
    expected = Rails.application.credentials.central_bank_access_code ||
               ENV['CENTRAL_BANK_ACCESS_CODE']

    if expected.present? && ActiveSupport::SecurityUtils.secure_compare(params[:access_code].to_s, expected.to_s)
      session[:central_bank_authenticated] = true
      return_to = session.delete(:central_bank_return_to) || technical_overview_path
      redirect_to return_to, notice: "Secure session established."
    else
      flash.now[:alert] = "Invalid access code. Contact the protocol team to request credentials."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:central_bank_authenticated)
    redirect_to root_path, notice: "Secure session ended."
  end
end
