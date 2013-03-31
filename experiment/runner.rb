require 'csv'

require 'bundler'
Bundler.require(:default, :development)
require 'active_record'

database_path = File.expand_path("../database.sqlite3", __FILE__)
FileUtils.rm(database_path) if File.exists?(database_path)
ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => database_path
)
ActiveRecord::Base.connection.execute <<-SQL
  CREATE TABLE IF NOT EXISTS page_versions (
    id integer,
    version integer,
    body text NOT NULL,
    PRIMARY KEY (id, version)
  )
SQL

files = Dir.glob(File.expand_path('../data/*.txt', __FILE__)).sort

results = [Array.new(files.length) { |i| i }]

class PageVersion < ActiveRecord::Base
  self.primary_keys = [:id, :version]
end

class Page1 < ActiveRecord::Base
  include PatchLog
  patch_log :body
end

class Page2 < ActiveRecord::Base
  include PatchLog
  patch_log :body
  self.patch_log_delimiter = /[[:space:]]/
end

column = []
results << column
files.each do |file|
  data = File.read(file).force_encoding('ISO-8859-1').encode('UTF-8')
  time = Time.now
  PageVersion.create!(
    :id => 1,
    :version => time.to_i * 1_000_000 + time.usec,
    :body => data)

  column << File.size(database_path)
end

column = []
results << column
FileUtils.rm(database_path) if File.exists?(database_path)
ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => database_path
)
ActiveRecord::Base.connection.execute <<-SQL
  CREATE TABLE IF NOT EXISTS page1s (
    id integer PRIMARY KEY AUTOINCREMENT,
    current_version_id integer NOT NULL,
    body text NOT NULL
  )
SQL
ActiveRecord::Base.connection.execute <<-SQL
  CREATE TABLE IF NOT EXISTS page1_diffs (
    page1_id integer,
    version_id integer,
    body_diff text NOT NULL,
    PRIMARY KEY (page1_id, version_id)
  )
SQL
files.each_with_index do |file, i|
  data = File.read(file).force_encoding('ISO-8859-1').encode('UTF-8')
  if i.zero?
    Page1.create!(:id => 1, :body => data)
  else
    Page1.find(1).update_attributes!(:body => data)
  end

  column << File.size(database_path)
end

column = []
results << column
FileUtils.rm(database_path) if File.exists?(database_path)
ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => database_path
)
ActiveRecord::Base.connection.execute <<-SQL
  CREATE TABLE IF NOT EXISTS page2s (
    id integer PRIMARY KEY AUTOINCREMENT,
    current_version_id integer NOT NULL,
    body text NOT NULL
  )
SQL
ActiveRecord::Base.connection.execute <<-SQL
  CREATE TABLE IF NOT EXISTS page2_diffs (
    page2_id integer,
    version_id integer,
    body_diff text NOT NULL,
    PRIMARY KEY (page2_id, version_id)
  )
SQL
files.each_with_index do |file, i|
  data = File.read(file).force_encoding('ISO-8859-1').encode('UTF-8')
  if i.zero?
    Page2.create!(:id => 1, :body => data)
  else
    Page2.find(1).update_attributes!(:body => data)
  end

  column << File.size(database_path)
end

CSV.open(File.expand_path('../results.csv', __FILE__), 'w') do |csv|
  csv << %w(versions copies diffs tokendiffs)
  results.transpose.each do |row|
    csv << row
  end
end
