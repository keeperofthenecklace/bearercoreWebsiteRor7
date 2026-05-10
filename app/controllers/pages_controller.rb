class PagesController < ApplicationController
  def home
  end

  def technical_overview
  end

  def litepaper
    respond_to do |format|
      format.pdf do
        render pdf:         "bearerCORE-Litepaper-#{Date.today.strftime('%Y%m')}",
               layout:      "pdf",
               disposition:  "attachment",
               page_size:   "A4",
               dpi:         150,
               margin:      { top: 0, bottom: 0, left: 0, right: 0 }
      end
    end
  end
end
