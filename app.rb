#!/usr/bin/env ruby -I ../lib -I lib
# coding: utf-8
require 'sinatra'
require './lib/model'
require 'json'
#set :server, 'thin'
enable :sessions
connections = []  # XXX: Won't when across multiple servers :(

# TODO:
# Schema: index user handle

get '/' do
  user_handle = params[:user]
  if user_handle
    session['handle'] = user_handle
    @user = User.find_by handle: user_handle # Will raise an exception if there's no matching record
    # TODO: Get tasks
    @tasks = Task.all()
    @current_task_priority = 0
    if !@user.current_task_id.nil?
      current_task = Task.find(@user.current_task_id)
      @current_task_priority = current_task.priority
    end

    erb :chat_ng, :locals => { :current_task_id => @user.current_task_id, 
        :current_task_priority => @current_task_priority }, :layout => false
  else
    @users = User.all().order(:handle)
    erb :login, :layout => false
  end
end

# SERVER-SENT EVENTS ##########################################################

get '/stream', :provides => 'text/event-stream' do
  stream :keep_open do |out|
    connections << out
    out.callback { connections.delete(out) }  # Callback for disconnecting
    # TODO?: out.errback do
  end
end

post '/' do
  connections.each { |out| out << "data: #{params[:msg]}\n\n" }
  204 # response without entity body
end

def send_message(connections, msg_json)
  puts "DEBUG: " << msg_json
  connections.each { |out| out << "data: #{msg_json}\n\n" }
end

# TASKS API ###################################################################

post '/api/tasks/start/:task_id' do
  content_type :json
  task_id = params[:task_id].to_i
  if task_id > 0
    user = get_current_user()
    user.current_task_id = task_id
    success = user.save()

    # Need to return task priority
    current_task = Task.find(user.current_task_id)
    # Also need to update task list
    important_tasks = Task.find_important(current_task)
    {:success => success, 'current_task' => current_task, :tasks => important_tasks}.to_json
  else
    [500, {:error => 'id must be greater than 0'}.to_json]
  end
end

# XXX: :dummy simplifies frontend integration 
post '/task/stop/:dummy' do
  content_type :json
  user = get_current_user()
  user.current_task_id = nil
  success = user.save()
  {:success => success}.to_json
end

get '/tasks/' do
  @task_list = Task.all().order(:priority);
  erb :task_admin_ng, :layout => false
end

get '/api/user/tasks' do
  content_type :json
  user = get_current_user()
  if user.current_task_id.nil?
    tasks = Task.order(priority: :desc)
  else
    current_task = Task.find(user.current_task_id)
    #tasks = Task.includes({messages: {user: :handle}}).where("priority <= ?", current_task.priority)
    tasks = Task.includes({:messages => [:user]})
      .where("priority >= ?", current_task.priority)
      .order(priority: :desc)
    
  end
  {:tasks => tasks}.to_json(:include => {:messages => {:include => {:user => {:only => :handle }}}})
end

get '/api/tasks/' do
  content_type :json
  tasks = Task.all().order(:priority)
  {:tasks => tasks}.to_json
end

post '/api/tasks/' do
  content_type :json
  data = read_json_body(request.body)
  task_id = data['id'].to_i

  task = (task_id > 0) ? Task.find(task_id) : Task.new
  task.title = data['title']
  task.priority = data['priority']

  success = task.save()  
  send_message(connections, task.to_msg_json('create'))
  {:success => success, 'task' => task}.to_json
end

delete '/api/tasks/:task_id' do
  content_type :json
  #data = read_json_body(request.body)
  task_id = params['task_id'].to_i

  success = Task.delete(task_id)
  {:success => success, 'task_id' => task_id}.to_json
end

# MESSAGE API #################################################################

# @param current-task-id optional
get '/api/messages/' do
  content_type :json
  task_id = params['current-task-id']
  min_priority = 0
  if !task_id.empty?
    task = Task.find(task_id)
    min_priority = task.priority unless task.nil?
  end
  #messages = Message.includes(:user).joins(:task).where('tasks.priority >= ?', min_priority)
  messages = Message.includes(:user).joins("LEFT OUTER JOIN tasks ON messages.task_id = tasks.id").where('(tasks.priority >= ?) or (task_id = 0)', min_priority)
  # TODO: Handle limit
  {:messages => messages}.to_json(:include => {:user => {:only => :handle }})
end

post '/api/messages/send/' do
  content_type :json
  data = read_json_body(request.body)
  task_id = data['task_id'].to_i
  user_id = data['from_user'].to_i

  message = Message.new(task_id: task_id, msg: data['msg'], from_user: user_id)
  success = message.save()

  user = User.find(user_id)
  send_message(connections, message.to_msg_json('create', user))
  {:success => success, 'message' => message}.to_json
end

# HELPER ######################################################################

# Raises an exception if there's no current user
def get_current_user() 
  user_handle = session['handle']
  if user_handle.nil? 
    raise "Session has no user handle"
  else
    User.find_by(handle: user_handle)
  end
end

def read_json_body(body)
  body.rewind  # in case someone already read it
  JSON.parse body.read
end
