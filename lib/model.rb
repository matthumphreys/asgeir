require 'sinatra'
require 'sinatra/activerecord'
require 'yaml'
require './environments'
require 'json'

#DB_CONFIG = YAML::load(File.open('config/database.yml'))
#set :database, "mysql://#{DB_CONFIG['username']}:#{DB_CONFIG['password']}@#{DB_CONFIG['host']}:#{DB_CONFIG['port']}/#{DB_CONFIG['database']}"
#set :database_file, "config/database.yml"

class User < ActiveRecord::Base
end

class Task < ActiveRecord::Base
	def to_msg_json(action)
		{'entityType' => 'task', 'actionType' => action, 'entityData' => {
			:title => self.title
		}}.to_json
	end
end

class Message < ActiveRecord::Base
	def to_msg_json(action, user)
		{:entityType => 'message', :actionType => action, :entityData => {
			:taskId => self.task_id, :msg => self.msg, :fromUser => {
					:id => user.id,
					:handle => user.handle
				}
			}
		}.to_json
	end
end