# Crea/promueve el primer admin de producción al bootear el server, leyendo
# ADMIN_EMAIL/ADMIN_PASSWORD de las variables de entorno (nunca hardcodeado en
# el código ni en el repo). Existe porque el plan Free de Render no tiene
# Shell ni Pre-Deploy Command -- sin esto no habría forma de crear el primer
# admin sin subir de plan.
#
# - `defined?(Rails::Server)` asegura que esto solo corre cuando el proceso es
#   el server real (`bin/rails server`), no en rake tasks / consola / el
#   `assets:precompile` del build de Render -- evita pegarle a la base antes
#   de que existan migraciones corridas.
# - Nunca pisa la contraseña de una cuenta que ya existía (`forzar_password`
#   queda en `false` acá a propósito, ver `User.crear_o_promover_admin!`),
#   así que dejar las variables seteadas para siempre es seguro: crea el
#   admin una sola vez. Además solo puede existir un admin en todo el sistema
#   (`User#solo_un_admin_en_el_sistema`) — si este bootstrap corriera con un
#   email distinto al del admin ya creado, falla y queda solo logueado.
# - Si falla por lo que sea (la base todavía no está lista en ese boot puntual,
#   etc.) se loguea y se sigue -- nunca debe tumbar el arranque de la app por
#   un paso que es solo de conveniencia.
if defined?(Rails::Server) && ENV["ADMIN_EMAIL"].present? && ENV["ADMIN_PASSWORD"].present?
  Rails.application.config.after_initialize do
    begin
      usuario = User.crear_o_promover_admin!(email: ENV["ADMIN_EMAIL"], password: ENV["ADMIN_PASSWORD"])
      Rails.logger.info("[admin_bootstrap] Admin listo: #{usuario.email}")
    rescue StandardError => e
      Rails.logger.warn("[admin_bootstrap] No se pudo crear/promover el admin: #{e.class} #{e.message}")
    end
  end
end
