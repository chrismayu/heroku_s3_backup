namespace :heroku do
  desc "Backup Database, gzip and upload to Amazon S3"
  task :backup => :environment do

    job = HerokuS3Backup::BackupJob.new
    job.create_backup

  end
end
