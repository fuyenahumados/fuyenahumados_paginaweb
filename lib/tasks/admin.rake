# El usuario admin ya no vive en db/seeds.rb (ver comentario al inicio de ese
# archivo) porque no es contenido de negocio versionable — es una cuenta real.
# Esta tarea es la forma de crear el admin (solo puede existir uno, ver
# User#solo_un_admin_en_el_sistema) o de actualizar su contraseña/datos si ya
# existe, tanto en desarrollo como la primera vez en producción (Render).
namespace :admin do
  desc "Crea el admin (o actualiza su contraseña/datos si ya existe). Uso: bin/rails admin:crear EMAIL=admin@fuyen.cl PASSWORD=xxxxxx"
  task crear: :environment do
    email    = ENV.fetch("EMAIL")    { abort "Falta EMAIL. Uso: bin/rails admin:crear EMAIL=admin@fuyen.cl PASSWORD=xxxxxx" }
    password = ENV.fetch("PASSWORD") { abort "Falta PASSWORD. Uso: bin/rails admin:crear EMAIL=admin@fuyen.cl PASSWORD=xxxxxx" }

    usuario = User.crear_o_promover_admin!(
      email: email, password: password,
      nombre: ENV["NOMBRE"], apellido: ENV["APELLIDO"], telefono: ENV["TELEFONO"],
      forzar_password: true
    )

    puts "Admin listo: #{usuario.email}"
  rescue ActiveRecord::RecordInvalid => e
    abort "No se pudo: #{e.record.errors.full_messages.join(', ')}"
  end
end
