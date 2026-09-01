# El usuario admin ya no vive en db/seeds.rb (ver comentario al inicio de ese
# archivo) porque no es contenido de negocio versionable — es una cuenta real.
# Esta tarea es la forma de crear/promover un admin, tanto en desarrollo como
# la primera vez en producción (Render).
namespace :admin do
  desc "Crea o promueve un usuario a admin. Uso: bin/rails admin:crear EMAIL=admin@fuyen.cl PASSWORD=xxxxxx"
  task crear: :environment do
    email    = ENV.fetch("EMAIL")    { abort "Falta EMAIL. Uso: bin/rails admin:crear EMAIL=admin@fuyen.cl PASSWORD=xxxxxx" }
    password = ENV.fetch("PASSWORD") { abort "Falta PASSWORD. Uso: bin/rails admin:crear EMAIL=admin@fuyen.cl PASSWORD=xxxxxx" }

    usuario = User.crear_o_promover_admin!(
      email: email, password: password,
      nombre: ENV["NOMBRE"], apellido: ENV["APELLIDO"], telefono: ENV["TELEFONO"]
    )

    puts "Admin listo: #{usuario.email}"
  end
end
