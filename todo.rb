require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

helpers do
  def is_completed(list)
    list[:todos].all? { |todo| todo[:completed] }
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
    lists.sort_by { |list| is_completed(list) ? 1 : 0 }
  end
end

configure do
  enable :sessions
  set :session_secret, 'secret'
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
  @list = session[:lists].select { |list| list[:id] == params[:id] }.first
  erb :list, layout: :layout
end

get "/lists/:id/edit" do
  @list = session[:lists].select { |list| list[:id] == params[:id] }.first
  erb :edit_list, layout: :layout
end

post "/lists/:id/edit" do
  @list = session[:lists].select { |list| list[:id] == params[:id] }.first
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

post "/lists/:id/delete" do
  @list = session[:lists].select { |list| list[:id] == params[:id] }.first
  session[:lists].delete(@list)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

# Return an error message if the todo name is invalid. Return nil if name is valid.
def error_for_todo(name)
  if !(1..100).cover? name.size
    "Todo must be between 1 and 100 characters."
  end
end

current_todo_id = 0

post "/lists/:list_id/todos" do
  @list = session[:lists].select { |list| list[:id] == params[:list_id] }.first
  text = params[:todo].strip
  error = error_for_todo(text)

  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: text, completed: false, id: current_todo_id }
    current_todo_id += 1
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

current_list_id = 0

post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [], id: current_list_id.to_s }
    current_list_id += 1
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# Mark all todos of the list as completed
post "/lists/:id/complete_all" do
  @list = session[:lists].select { |list| list[:id] == params[:id] }.first
  @list[:todos].each do |todo|
    todo[:completed] = true
  end
  session[:success] = "All todos have been completed."
  redirect "/lists/#{params[:id]}"
end

# Delete a todo
post "/lists/:list_id/todos/:todo_id/delete" do
  @list = session[:lists].select { |list| list[:id] == params[:list_id] }.first
  @list[:todos].delete_if { |todo| todo[:id] == params[:todo_id].to_i }
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{params[:list_id]}"
end

# Update the status of a todo
post "/lists/:list_id/todos/:id" do
  @list = session[:lists].select { |list| list[:id] == params[:list_id] }.first
  @todo = @list[:todos].select { |todo| todo[:id] == params[:id].to_i }.first
  @todo[:completed] = (params[:completed] == "true")
  session[:success] = "The todo has been updated."
  redirect "/lists/#{@list[:id]}"
end