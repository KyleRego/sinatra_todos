require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

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
  selected_list = session[:lists].select { |list| list[:id].to_i == list_id.to_i }.first
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
  session[:lists] ||= []
end

get '/' do
  redirect "/lists"
end

get "/lists" do
  @lists = session[:lists]
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
    @list[:name] = list_name
    session[:success] = "The list has been renamed."
    redirect "/lists/#{@list[:id]}"
  end
end

# Delete a todo list
post "/lists/:id/delete" do
  @list = load_list(params[:id])
  session[:lists].delete(@list)
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

def next_todo_id(todos)
  max = todos.map { |todo| todo[:id] }.max || 0
  max + 1
end

post "/lists/:list_id/todos" do
  @list = load_list(params[:list_id])
  text = params[:todo].strip
  error = error_for_todo(text)

  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: text, completed: false, id: next_todo_id(@list[:todos]) }
    redirect "/lists/#{params[:list_id]}"
  end
end

# Return an error message if the list name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

def next_list_id(lists)
  p lists
  max = lists.map{ |list| list[:id] }.max || 0
  max + 1
end

post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [], id: next_list_id(session[:lists]) }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# Mark all todos of the list as completed
post "/lists/:id/complete_all" do
  @list = load_list(params[:id])
  @list[:todos].each do |todo|
    todo[:completed] = true
  end
  session[:success] = "All todos have been completed."
  redirect "/lists/#{params[:id]}"
end

# Delete a todo
post "/lists/:list_id/todos/:todo_id/delete" do
  @list = load_list(params[:list_id])
  @list[:todos].delete_if { |todo| todo[:id] == params[:todo_id].to_i }
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
  @todo[:completed] = (params[:completed] == "true")
  session[:success] = "The todo has been updated."
  redirect "/lists/#{@list[:id]}"
end