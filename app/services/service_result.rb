# Verdict d'un service appelé depuis un contrôleur : ça a marché ou pas, et le message à
# montrer au joueur. Le contrôleur n'a plus qu'à le passer à `redirect_with`, qui le flashe
# en vert ou en rouge.
ServiceResult = Struct.new(:ok, :message, keyword_init: true) do
  def self.ok(message)  = new(ok: true, message:)
  def self.err(message) = new(ok: false, message:)
end
