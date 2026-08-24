# Sovereign jurisdiction lock for the Governor's Macro-Corridor Console.
#
# A national central-bank Governor may only act on corridors that ORIGINATE in
# their home country (source). The console rides the browser session cookie on
# same-origin /api/v2 fetches, so the home country + role are read from the
# session (session[:country_code] / session[:role], bound by the auth bridge).
#
# Bypass:
#   • role == "system_admin"  → platform superuser, unrestricted
#   • blank home country      → demo / unauthenticated console (nothing to enforce)
module SovereignOriginGuard
  extend ActiveSupport::Concern

  private

  # Renders 403 sovereign_jurisdiction_violation and returns false when the target
  # corridor's origin is outside the operator's home country; returns true (and
  # renders nothing) when the request may proceed. In a before_action the render
  # halts the chain automatically.
  def enforce_sovereign_origin!(corridor_ident, explicit_source: nil)
    home = session[:country_code].to_s.strip.upcase
    role = session[:role].to_s

    return true if role == "system_admin" # platform superuser
    return true if home.blank?            # demo / no bound jurisdiction

    source = (explicit_source.presence || sovereign_source_country(corridor_ident)).to_s.upcase
    return true if source.blank?          # unknown corridor — let the action 404 on its own
    return true if source == home

    render json: {
      error:   "sovereign_jurisdiction_violation",
      message: "Corridor origin #{source} is outside your sovereign jurisdiction (#{home}). " \
               "You may only manage corridors where #{home} is the source."
    }, status: :forbidden
    false
  end

  # Resolve a corridor identifier (numeric id, "GHA-NGA" code, or "GHA → NGA"
  # display) to its source_country ISO-alpha3.
  def sovereign_source_country(ident)
    ident = ident.to_s.strip
    return nil if ident.blank?

    corr = Api::V2::CorridorsController.corridors_data.find { |c|
      c[:id].to_s == ident || c[:code].to_s == ident
    }
    return corr[:source_country] if corr

    # Fallback: parse "GHA → NGA" / "GHA->NGA" / "GHA-NGA"
    if ident =~ /\A([A-Za-z]{2,3})\s*(?:→|->|-)\s*([A-Za-z]{2,3})\z/
      return Regexp.last_match(1).upcase
    end
    nil
  end
end
