# El usuario admin ya no vive en db/seeds.rb (ver comentario al inicio de ese
# archivo) porque no es contenido de negocio versionable — es una cuenta real.
# Esta tarea es la forma de crear/promover un admin, tanto en desarrollo como
# la primera vez en producción (Render).
namespace :admin do
  desc "Crea o promueve un usuario a admin. Uso: bin/rails admin:crear EMAIL=admin@fuyen.cl PASSWORD=xxxxxx"
  task crear: :environment do
    email    = ENV.fetch("EMAIL")    { abort "Falta EMAIL. Uso: bin/rails admin:crear EMAIL=admin@fuyen.cl PASSWORD=xxxxxx" }
    password = ENV.fetch("PASSWORD") { abort "Falta PASSWORD. Uso: bin/rails admin:crear EMAIL=admin@fuyen.cl PASSWORD=xxxxxx" }

    usuario = User.find_or_initialize_by(email: email)
    usuario.password = password if usuario.new_record?
    usuario.nombre    = ENV.fetch("NOMBRE", usuario.nombre.presence || "Admin")
    usuario.apellido  = ENV.fetch("APELLIDO", usuario.apellido.presence || "Fuyén")
    usuario.telefono  = ENV.fetch("TELEFONO", usuario.telefono.presence || "+56900000000")
    usuario.role      = :admin
    usuario.save!

    puts "Admin listo: #{usuario.email}"
  end
end
