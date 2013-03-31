require 'bundler'
Bundler.require :default, :development

require 'active_record'

Dir.glob(File.expand_path('../../models/*.rb', __FILE__)).
  each { |model| require(model) }

RSpec.configure do |config|

  config.before :all do
    ActiveRecord::Base.establish_connection(
      :adapter => "sqlite3",
      :database => File.expand_path("../../database.sqlite3", __FILE__)
    )
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE TABLE IF NOT EXISTS pages (
        id integer PRIMARY KEY AUTOINCREMENT,
        current_version_id integer NOT NULL,
        title text NOT NULL,
        body text NOT NULL
      )
    SQL
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE TABLE IF NOT EXISTS page_diffs (
        page_id integer,
        version_id integer,
        body_diff text NOT NULL,
        PRIMARY KEY (page_id, version_id)
      )
    SQL
  end

  config.after(:all) do
    FileUtils.rm(File.expand_path("../../database.sqlite3", __FILE__))
  end

  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

end
