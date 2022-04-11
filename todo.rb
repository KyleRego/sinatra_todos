require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

require_relative "session_persistence"

helpers do
  def is_completed?(list)
    list[:todos].all? { |todo| todo[:completed] } && list[:todos].size > 0
  end

  def count_todos(list)
    list[:todos].size
  end
  
  def count_completed_todos(list)
    list[:todos].count { |todo| todo[:completed] }
  end

  def sorted_todos(list)
    list[:todos].sort_by { |todo| todo[:completed] ? 1 : 0 }
  end

  def sorted_lists(lists)
    lists.sort_by { |list| is_completed?(list) ? 1 : 0 }
  end
end

def load_list(list_id)
  selected_list = @storage.find_list(list_id)
  if selected_list.nil?
    session[:error] = "That list does not exist"
    redirect "/lists"
  end
  selected_list
end

configure do
  enable :sessions
  set :session_secret, 'secret'
end

configure do
  set :erb, :escape_html => true
end

before do
  @storage = SessionPersistence.new(session)
end

get '/' do
  redirect "/lists"
end

get "/lists" do
  @lists = @storage.all_lists
  erb :lists, layout: :layout
end

get "/lists/new" do
  erb :new_list, layout: :layout
end

get "/lists/:id" do
  @list = load_list(params[:id])
  erb :list, layout: :layout
end

get "/lists/:id/edit" do
  @list = load_list(params[:id])
  erb :edit_list, layout: :layout
end

post "/lists/:id/edit" do
  @list = load_list(params[:id])
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    # @list[:name] = list_name
    @storage.update_list_name(params[:id], list_name)
    session[:success] = "The list has been renamed."
    redirect "/lists/#{@list[:id]}"
  end
end

# Delete a todo list
post "/lists/:id/delete" do
  @storage.delete_list(params[:id])
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "The list has been deleted."
    redirect "/lists"
  end
end

# Return an error message if the todo name is invalid. Return nil if name is valid.
def error_for_todo(name)
  if !(1..100).cover? name.size
    "Todo must be between 1 and 100 characters."
  end
end

post "/lists/:list_id/todos" do
  @list = load_list(params[:list_id])
  text = params[:todo].strip
  error = error_for_todo(text)

  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @storage.create_new_todo(params[:list_id], text)
    session[:success] = "The todo was added."
    redirect "/lists/#{params[:list_id]}"
  end
end

# Return an error message if the list name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif @storage.all_lists.any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    @storage.create_new_list(list_name)
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# Mark all todos of the list as completed
post "/lists/:id/complete_all" do
  @storage.mark_all_todos_as_completed(params[:id])
  session[:success] = "All todos have been completed."
  redirect "/lists/#{params[:id]}"
end

# Delete a todo
post "/lists/:list_id/todos/:todo_id/delete" do
  @list = load_list(params[:list_id])
  @storage.delete_todo_from_list(params[:list_id], params[:todo_id])
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo has been deleted."
    redirect "/lists/#{params[:list_id]}"
  end
end

# Update the status of a todo
post "/lists/:list_id/todos/:id" do
  @list = load_list(params[:list_id])
  @todo = @list[:todos].select { |todo| todo[:id] == params[:id].to_i }.first
  @storage.update_todo_status(params[:list_id], params[:id], params[:completed])
  session[:success] = "The todo has been updated."
  redirect "/lists/#{@list[:id]}"
end