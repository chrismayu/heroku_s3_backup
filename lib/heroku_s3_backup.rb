require 'fog'

module HerokuS3Backup

end

require "heroku_s3_backup/backup_job"
require "heroku_s3_backup/railtie" if defined?(Rails)
