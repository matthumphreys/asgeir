#!/usr/bin/env ruby -I ../lib -I lib
# coding: utf-8
require 'sinatra'
require './lib/model'
require 'json'
#set :server, 'thin'
enable :sessions
connections = []

# TODO:
# Schema: index user handle

get '/' do
  user_handle = params[:user]
  if user_handle
    session['handle'] = user_handle
    @user = User.find_by handle: user_handle # Will raise an exception if there's no matching record
    # TODO: Get tasks
    @tasks = Task.all()
    erb :chat_ng, :locals => { :user => @user.handle, :current_task_id => @user.current_task_id }, :layout => false
  else
    @users = User.all().order(:handle)
    erb :login, :layout => false
  end
end

# SERVER-SENT EVENTS ##########################################################

get '/stream', :provides => 'text/event-stream' do
  stream :keep_open do |out|
    connections << out
    out.callback { connections.delete(out) }
  end
end

post '/' do
  connections.each { |out| out << "data: #{params[:msg]}\n\n" }
  204 # response without entity body
end

# TASKS API ###################################################################

post '/task/start/:task_id' do
  content_type :json
  task_id = params[:task_id].to_i
  if task_id > 0
    user = get_current_user()
    user.current_task_id = task_id
    saved = user.save()
    {:success => saved, 'taskId' => task_id}.to_json
  else
    [500, {:error => 'id must be greater than 0'}.to_json]
  end
end

# XXX: :dummy simplifies frontend integration 
post '/task/stop/:dummy' do
  content_type :json
  user = get_current_user()
  user.current_task_id = nil
  saved = user.save()
  {:success => saved}.to_json
end

get '/tasks/' do
  @task_list = Task.all().order(:priority);
  erb :tasks, :layout => false
end

get '/user/tasks' do
  content_type :json
  user = get_current_user()
  if user.current_task_id.nil?
    tasks = Task.all()
  else
    current_task = Task.find(user.current_task_id)
    tasks = Task.where("priority <= ?", current_task.priority)
  end
  {:tasks => tasks}.to_json
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
