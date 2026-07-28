# Sert le manifest et le service worker de la PWA. On n'utilise pas Rails::PwaController :
# il rend "pwa/service-worker" sans forcer le format, or la requête d'enregistrement d'un
# service worker arrive en Accept: */* (format :html) et le template est un .js →
# MissingTemplate 500. D'où le formats: explicite ici.
class PwaController < ApplicationController
  # Assets publics : la protection anti-JSONP refuserait de rendre du .js à une
  # requête non-XHR (le navigateur enregistre le SW par un GET classique).
  skip_forgery_protection

  def service_worker
    render template: "pwa/service-worker", layout: false, formats: [:js]
  end

  def manifest
    render template: "pwa/manifest", layout: false, formats: [:json]
  end
end
