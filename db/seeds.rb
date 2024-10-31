# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create default users
users = [
  { email: 'admin@example.com', password: 'password', name: 'Admin User' },
  { email: 'user1@example.com', password: 'password', name: 'User One' },
  { email: 'user2@example.com', password: 'password', name: 'User Two' }
]

users.each do |user_data|
  User.find_or_create_by!(email: user_data[:email]) do |u|
    u.password = user_data[:password]
    u.password_confirmation = user_data[:password]
    u.name = user_data[:name]
  end
end

# Create controllers
controllers = [
  { name: 'Controller 1', location: 'Building A', user: User.find_by(email: 'admin@example.com') },
  { name: 'Controller 2', location: 'Building B', user: User.find_by(email: 'user1@example.com') },
  { name: 'Controller 3', location: 'Building C', user: User.find_by(email: 'user2@example.com') }
]

controllers.each do |controller_data|
  Controller.find_or_create_by!(name: controller_data[:name], location: controller_data[:location], user: controller_data[:user])
end

# Create lockers
lockers = [
  { number: 101, state: true, owner_email: 'owner1@example.com', controller: Controller.find_by(name: 'Controller 1') },
  { number: 102, state: false, owner_email: 'owner2@example.com', controller: Controller.find_by(name: 'Controller 1') },
  { number: 201, state: true, owner_email: 'owner3@example.com', controller: Controller.find_by(name: 'Controller 2') },
  { number: 202, state: false, owner_email: 'owner4@example.com', controller: Controller.find_by(name: 'Controller 2') },
  { number: 301, state: true, owner_email: 'owner5@example.com', controller: Controller.find_by(name: 'Controller 3') },
  { number: 302, state: false, owner_email: 'owner6@example.com', controller: Controller.find_by(name: 'Controller 3') }
]

lockers.each do |locker_data|
  Locker.find_or_create_by!(number: locker_data[:number], state: locker_data[:state], owner_email: locker_data[:owner_email], controller: locker_data[:controller])
end

# Create models
models = [
  { name: 'Model 1', active: true },
  { name: 'Model 2', active: false },
  { name: 'Model 3', active: true },
  { name: 'Model 4', active: false },
  { name: 'Model 5', active: true },
  { name: 'Model 6', active: false }
]

models.each do |model_data|
  Model.find_or_create_by!(name: model_data[:name], active: model_data[:active])
end
