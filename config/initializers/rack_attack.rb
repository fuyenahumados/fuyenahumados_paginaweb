Rails.application.config.middleware.use Rack::Attack

class Rack::Attack
  cache.store = Rails.cache

  # Frena fuerza bruta contra el login: máximo 10 intentos cada 20 segundos
  # por IP, y 5 intentos por minuto contra un mismo email — esto último evita
  # que alguien pruebe contraseñas contra la cuenta de un admin puntual aunque
  # rote de IP. Sin esto, ahora que el sitio ya no exige token de acceso,
  # /users/sign_in queda expuesto a cualquiera en internet.
  throttle("login/ip", limit: 10, period: 20.seconds) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  throttle("login/email", limit: 5, period: 1.minute) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params.dig("user", "email").to_s.downcase.presence
    end
  end

  # Mismo criterio para "recuperar contraseña" — evita que alguien use ese
  # formulario para confirmar a fuerza bruta qué emails existen en la base.
  throttle("password_reset/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.path == "/users/password" && req.post?
  end
end
