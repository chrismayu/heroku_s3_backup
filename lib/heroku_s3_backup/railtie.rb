require 'heroku_s3_backup'

module HerokuS3Backup
  require 'rails'
  class Railtie < Rails::Railtie
    railtie_name :heroku_s3_backup

    rake_tasks do
      load "tasks/heroku.rake"
    end
  end
end
