# db/seeds.rb

# Limpiar la base de datos existente
puts "Limpiando base de datos..."
ModelUpdate.destroy_all
LockerPassword.destroy_all
LockerEvent.destroy_all
Locker.destroy_all
Gesture.destroy_all
Controller.destroy_all
Model.destroy_all
User.destroy_all

puts "Creando usuarios..."
# Crear superusuario
super_user = User.create!(
  email: 'admin@example.com',
  password: 'password123',
  name: 'Super Admin',
  is_superuser: true,
  provider: 'google_oauth2',
  uid: '123456789',
  avatar_url: 'https://api.dicebear.com/7.x/avataaars/svg?seed=admin'
)

# Crear usuarios normales
normal_users = 1.times.map do |i|
  User.create!(
    email: "user#{i+1}@example.com",
    password: 'password123',
    name: "User #{i+1}",
    is_superuser: false,
    provider: 'google_oauth2',
    uid: "user#{i+1}",
    avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=user#{i+1}"
  )
end

puts "Creando modelos de IA..."
# Crear modelos de IA con archivos adjuntos
models = [
  {
    name: "Modelo Básico v1",
    active: false,
    size_bytes: 500000,
    user: super_user, # Add user association
    file_content: "Contenido del modelo básico v1"
  },
  {
    name: "Modelo Estándar v2",
    active: true,
    size_bytes: 750000,
    user: super_user, # Add user association
    file_content: "Contenido del modelo estándar v2"
  },
  {
    name: "Modelo Premium v3",
    active: true,
    size_bytes: 1000000,
    user: super_user, # Add user association
    file_content: "Contenido del modelo premium v3"
  }
].map do |model_data|
  file_content = model_data.delete(:file_content)
  model = Model.new(model_data)
  
  # Crear un archivo temporal y adjuntarlo al modelo
  temp_file = Tempfile.new(['model', '.h5'])
  temp_file.write(file_content)
  temp_file.rewind
  
  model.file.attach(
    io: temp_file,
    filename: "#{model_data[:name].parameterize}.h5",
    content_type: 'application/octet-stream'
  )
  
  model.save!
  temp_file.close
  temp_file.unlink
  model
end

puts "Creando gestos..."
# Gestos para cada modelo
GESTURE_NAMES = ['L', 'abierta', 'cero', 'chill', 'rock', 'suerte']
GESTURE_SYMBOLS = ['👆', '🖐', '✊', '👌', '🤘', '🤞']

models.each do |model|
  GESTURE_NAMES.each_with_index do |name, index|
    Gesture.create!(
      name: name,
      symbol: GESTURE_SYMBOLS[index],
      model: model
    )
  end
end

puts "Creando controladores..."
# Crear controladores
locations = ['Edificio Ingenieria', 'Edificio Humanidades', 'Edificio Ciencias', 'Cafetería', 'Biblioteca']
controllers = []

normal_users.each_with_index do |user, index|
  2.times do |i|
    controllers << Controller.create!(
      name: "Controlador #{index*2 + i + 1}",
      location: locations[index],
      user: user,
      model: models.sample,
      is_connected: [true, false].sample,
      last_connection: [Time.current, 15.minutes.ago, 1.hour.ago].sample
    )
  end
end

puts "Creando casilleros y contraseñas..."
# Crear casilleros y sus contraseñas
controllers.each do |controller|
  # Limitar a 4 casilleros por controlador
  4.times do |i|
    locker = Locker.create!(
      number: i + 1,
      state: [true, false].sample,
      owner_email: "cliente#{controller.id}_#{i+1}@example.com",
      controller: controller
    )

    # Crear contraseña aleatoria de 4 gestos
    gestures = controller.model.gestures.sample(4)
    gestures.each_with_index do |gesture, position|
      LockerPassword.create!(
        locker: locker,
        gesture: gesture,
        position: position
      )
    end

    # Crear eventos para cada casillero
    20.times do
      event_date = rand(30.days).seconds.ago
      LockerEvent.create!(
        locker: locker,
        event_type: ['open', 'close', 'password_attempt'].sample,
        success: [true, true, true, false].sample, # 75% de éxito
        event_time: event_date,
        created_at: event_date,
        updated_at: event_date
      )
    end
  end
end

puts "Creando actualizaciones de modelos..."
# Crear historial de actualizaciones de modelos
controllers.each do |controller|
  3.times do
    start_date = rand(30.days).seconds.ago
    completed_date = start_date + rand(30.minutes)
    status = ['succeeded', 'failed', 'pending', 'in_progress'].sample

    ModelUpdate.create!(
      controller: controller,
      model: models.sample,
      status: status,
      started_at: start_date,
      completed_at: ['succeeded', 'failed'].include?(status) ? completed_date : nil,
      created_at: start_date,
      updated_at: completed_date
    )
  end
end

puts "Seed completado!"

# Imprimir algunas estadísticas
puts "\nEstadísticas de la base de datos:"
puts "--------------------------------"
puts "Usuarios creados: #{User.count}"
puts "Modelos creados: #{Model.count}"
puts "Gestos creados: #{Gesture.count}"
puts "Controladores creados: #{Controller.count}"
puts "Casilleros creados: #{Locker.count}"
puts "Contraseñas de casilleros creadas: #{LockerPassword.count}"
puts "Eventos de casilleros creados: #{LockerEvent.count}"
puts "Actualizaciones de modelos creadas: #{ModelUpdate.count}"