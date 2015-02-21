module HerokuS3Backup
  class BackupJob

    def create_backup

      system_cmd =
        "PGPASSWORD=%s pg_dump -Fc -i --username=%s --host=%s %s > %s" %
        [db[:password], db[:username], db[:hostname], db[:db_name], output_filepath]

      puts "Executing system command: #{system_cmd}"

      system system_cmd

      `gzip #{output_filepath}`

      begin
        puts "Uploading #{gzipped_output_filepath} => #{bucket_name}/#{path}"
        bucket.files.create(:key => "#{path}/#{output_filename}.gz",
                               :body => open(gzipped_output_filepath))
      ensure
        puts "Removing tmp output file #{gzipped_output_filepath}"
        system "rm #{gzipped_output_filepath}"
      end

    end

    private

    def fog
      @fog ||= Fog::Storage.new(fog_credentials)
    end

    def fog_credentials
      {:provider => 'AWS',
        :region   => region,
        :aws_access_key_id => ENV['S3_ACCESS_KEY_ID'],
        :aws_secret_access_key => ENV['S3_SECRET_ACCESS_KEY']}

    end

    def database_var
      @database_var ||= (ENV['S3_DATABASE_BACKUP_DATABASE_VAR'] || 'DATABASE_URL')
    end

    def database_url
      @database_url ||= ENV[database_var]
    end

    def db
      @db ||= BackupJob::get_db_credentials(database_url)
    end

    def region
      @region ||= ENV['S3_DATABASE_BACKUP_REGION']
    end

    def bucket_name
      @bucket_name ||= ENV['S3_DATABASE_BACKUP_UPLOAD_BUCKET']
    end

    def bucket
      @bucket ||= fog.directories.get(bucket_name)
    end

    def path
      @path ||= ENV['S3_DATABASE_BACKUP_PATH']
    end

    def backup_name
      database_var.downcase
    end

    def output_filename
      @output_filename ||= "%s_%s.sql" %
        [backup_name, Time.now.strftime("%Y%m%d_%H%M%S")]
    end

    def output_filepath
      "tmp/#{output_filename}"
    end

    def gzipped_output_filepath
      "tmp/#{output_filename}.gz"
    end

    def self.get_db_credentials(url)
      puts "Parsing DB credentials from \"#{url}\""
      db = url.match(/postgres:\/\/([^:]+):([^@]+)@([^\/]+)\:[0-9]*\/(.+)/)
      creds = {}
      creds[:username] = db[1]
      creds[:password] = db[2]
      creds[:hostname] = db[3]
      creds[:db_name] = db[4]
      creds
    end

  end
end
