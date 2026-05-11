class PagesController < ApplicationController
  before_action :require_central_bank_access, only: [:technical_overview]

  def home
  end

  def technical_overview
  end

  def protocol_desk
  end

  def litepaper
    respond_to do |format|
      format.pdf do
        render pdf:                    "bearerCORE-Litepaper-#{Date.today.strftime('%Y%m')}",
               layout:                 "pdf",
               disposition:            "attachment",
               encoding:              "UTF-8",
               page_size:             "A4",
               dpi:                   150,
               margin:                { top: 0, bottom: 0, left: 0, right: 0 },
               disable_smart_shrinking: true,
               print_media_type:       false,
               no_stop_slow_scripts:   true,
               javascript_delay:       500
      end
    end
  end
end
