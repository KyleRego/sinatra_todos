require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

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
