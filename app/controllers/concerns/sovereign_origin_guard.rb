# Sovereign jurisdiction lock for the Governor's Macro-Corridor Console.
#
# A national central-bank Governor may only act on corridors LINKED to their home
# country — as origin (source) OR destination (target). The console rides the
# browser session cookie on same-origin /api/v2 fetches, so the home country +
# role are read from the session (session[:country_code] / session[:role], bound
# by the auth bridge).
#
# Bypass:
#   • role == "system_admin"  → platform superuser, unrestricted cross-corridor
#   • blank home country      → demo / unauthenticated console (nothing to enforce)
module SovereignOriginGuard
  extend ActiveSupport::Concern

  private

  # Renders 403 sovereign_jurisdiction_violation and returns false when the target
  # corridor touches neither the operator's home ISO as origin NOR destination;
  # returns true (rendering nothing) when the request may proceed. In a
  # before_action the render halts the chain automatically.
  def enforce_sovereign_origin!(corridor_ident, explicit_source: nil)
    home = session[:country_code].to_s.strip.upcase
    role = session[:role].to_s

    return true if role == "system_admin" # platform superuser
    return true if home.blank?            # demo / no bound jurisdiction

    isos = sovereign_corridor_isos(corridor_ident, explicit_source: explicit_source)
    return true if isos.empty?            # unknown corridor — let the action 404 on its own
    return true if isos.include?(home)    # home is the origin OR destination

    render json: {
      error:   "sovereign_jurisdiction_violation",
      message: "Corridor #{isos.join('→')} is outside your sovereign jurisdiction (#{home}). " \
               "You may only manage corridors where #{home} is the origin or destination."
    }, status: :forbidden
    false
  end

  # Resolve a corridor identifier (numeric id, "GHA-NGA" code, or "GHA → NGA"
  # display) to its [source, destination] ISO-alpha3 pair (upper-cased).
  def sovereign_corridor_isos(ident, explicit_source: nil)
    ident = ident.to_s.strip
    return [] if ident.blank?

    corr = Api::V2::CorridorsController.corridors_data.find { |c|
      c[:id].to_s == ident || c[:code].to_s == ident
    }
    if corr
      return [corr[:source_country], corr[:target_country]].compact.map { |x| x.to_s.upcase }
    end

    # Fallback: parse "GHA → NGA" / "GHA->NGA" / "GHA-NGA"
    if ident =~ /\A([A-Za-z]{2,3})\s*(?:→|->|-)\s*([A-Za-z]{2,3})\z/
      return [Regexp.last_match(1).upcase, Regexp.last_match(2).upcase]
    end

    [explicit_source].compact.map { |x| x.to_s.strip.upcase }.reject(&:blank?)
  end
end
