namespace :better_record do
  desc 'run better record setup'
  task install: :environment do |t, args|
    sh 'rails generate better_record:setup'
  end
end
