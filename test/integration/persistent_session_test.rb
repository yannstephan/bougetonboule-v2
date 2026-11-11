require "test_helper"

# Une PWA est fermée en permanence : un cookie de session sans date d'expiration disparaissait
# à chaque fermeture, et il fallait se reconnecter à chaque ouverture (donc jamais de push).
class PersistentSessionTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(firstname: "Coureur", email: "persistant@btb.test", password: "odyssea2027")
  end

  def session_cookie = response.headers["Set-Cookie"].to_s.split("\n").find { |c| c.start_with?("_bougetonboule_v2_session=") }

  test "se connecter pose un cookie qui survit à la fermeture de l'app" do
    post "/login", params: { email: @user.email, password: "odyssea2027" }

    assert_match(/expires=/i, session_cookie)
  end

  test "chaque visite repousse l'expiration" do
    post "/login", params: { email: @user.email, password: "odyssea2027" }
    get "/faq"

    assert_match(/expires=/i, session_cookie, "le cookie est réécrit : un an glissant, pas un an fixe")
  end
end
