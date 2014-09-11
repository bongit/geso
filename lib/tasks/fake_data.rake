namespace :db do
  desc "Fill database with sample data"
  task populate: :environment do
    admin = User.create!(name: "BON",
                         email: "celendipity@gmail.com",
                         password: "fathertime",
                         password_confirmation: "fathertime",
                         admin: true)
    99.times do |n|
      name  = Faker::Name.name
      email = "example-#{n+1}@railstutorial.jp"
      password  = "password"
      User.create!(name: name,
                   email: email,
                   password: password,
                   password_confirmation: password)
    end
  end
end