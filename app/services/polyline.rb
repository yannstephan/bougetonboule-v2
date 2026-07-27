# Décode une polyline encodée Google/Strava en liste de points [lat, lng].
# (Algorithme "Encoded Polyline" de Google, précision 5 décimales — celle de Strava.)
module Polyline
  module_function

  def decode(encoded)
    return [] if encoded.blank?

    points = []
    index = 0
    lat = 0
    lng = 0
    len = encoded.length

    while index < len
      lat_delta, index = next_value(encoded, index)
      lng_delta, index = next_value(encoded, index)
      lat += lat_delta
      lng += lng_delta
      points << [lat / 1e5, lng / 1e5]
    end
    points
  rescue StandardError => e
    Rails.logger.error("[Polyline] #{e.class}: #{e.message}")
    []
  end

  # Lit un entier zig-zag encodé à partir de `index`, renvoie [valeur, index_suivant].
  def next_value(encoded, index)
    shift = 0
    result = 0
    loop do
      byte = encoded[index].ord - 63
      index += 1
      result |= (byte & 0x1f) << shift
      shift += 5
      break if byte < 0x20
    end
    value = (result & 1).zero? ? (result >> 1) : ~(result >> 1)
    [value, index]
  end
end
