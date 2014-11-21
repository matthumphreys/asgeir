require 'sinatra'
require 'sinatra/activerecord'
require 'yaml'
require './environments'

#DB_CONFIG = YAML::load(File.open('config/database.yml'))
#set :database, "mysql://#{DB_CONFIG['username']}:#{DB_CONFIG['password']}@#{DB_CONFIG['host']}:#{DB_CONFIG['port']}/#{DB_CONFIG['database']}"
#set :database_file, "config/database.yml"

class User < ActiveRecord::Base
end

class Task < ActiveRecord::Base
end

class Message < ActiveRecord::Base
end