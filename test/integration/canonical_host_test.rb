require "test_helper"

# Strava n'accepte QU'UN SEUL « Authorization Callback Domain » par application, et le
# redirect_uri est construit depuis l'hôte de la requête : si un joueur arrive sur un autre
# hôte, « Connecter Strava » échoue sur `redirect_uri invalid`. D'où la redirection vers
# l'hôte canonique — et les deux exceptions qu'elle ne doit jamais franchir.
class CanonicalHostTest < ActionDispatch::IntegrationTest
  CANONICAL = "www.bougetonboule.fr".freeze

  setup do
    @previous = Rails.application.config.x.canonical_host
    Rails.application.config.x.canonical_host = CANONICAL
  end

  teardown { Rails.application.config.x.canonical_host = @previous }

  test "un GET sur un autre hôte est renvoyé en 301 vers l'hôte canonique, chemin conservé" do
    get "/login", headers: { "HOST" => "bougetonboule.fr" }

    assert_response :moved_permanently
    assert_equal "http://#{CANONICAL}/login", response.location
  end

  test "la chaîne de requête est conservée" do
    get "/login?from=strava", headers: { "HOST" => "bougetonboule.fr" }

    assert_equal "http://#{CANONICAL}/login?from=strava", response.location
  end

  test "l'URL .fly.dev est aussi renvoyée" do
    get "/login", headers: { "HOST" => "bougetonboule.fly.dev" }

    assert_response :moved_permanently
  end

  test "aucune redirection quand on est déjà sur l'hôte canonique" do
    get "/login", headers: { "HOST" => CANONICAL }

    assert_response :success
  end

  # ⚠️ Le test qui compte le plus : Strava ne suit pas les redirections. Une 301 ici ferait
  # échouer la validation de l'abonnement et perdre les courses.
  test "le webhook Strava n'est JAMAIS redirigé, même sur un autre hôte" do
    get "/strava/webhook",
        params: { "hub.verify_token" => "btb-verify", "hub.challenge" => "abc123",
                  "hub.mode" => "subscribe" },
        headers: { "HOST" => "bougetonboule.fr" }

    assert_not_equal 301, response.status, "le webhook a été redirigé : Strava perdrait les courses"
    assert_response :success
    assert_equal "abc123", response.parsed_body["hub.challenge"]
  end

  test "sans hôte canonique configuré (développement), rien n'est redirigé" do
    Rails.application.config.x.canonical_host = nil
    get "/login", headers: { "HOST" => "bougetonboule.fr" }

    assert_response :success
  end
end
