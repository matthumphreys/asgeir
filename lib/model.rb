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
	has_many :messages

	def to_msg_json(action)
		{:entity_type => 'task', :action_type => action, :entity_data => {
			:title => self.title
		}}.to_json
	end

end

class Message < ActiveRecord::Base
	belongs_to :user, 
		foreign_key: "from_user"


	def to_msg_json(action, user)
		{:entity_type => 'message', :action_type => action, :entity_data => {
			:task_id => self.task_id, :msg => self.msg, :user => {
					:id => user.id,
					:handle => user.handle
				}
			}
		}.to_json
	end
end