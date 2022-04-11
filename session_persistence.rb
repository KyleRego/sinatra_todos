class SessionPersistence
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def find_list(id)
    @session[:lists].select { |list| list[:id].to_i == id.to_i }.first
  end

  def all_lists
    @session[:lists]
  end

  def delete_list(id)
    list = find_list(id)
    @session[:lists].delete(list)
  end

  def create_new_list(list_name)
    all_lists << { name: list_name, todos: [], id: next_list_id(all_lists) }
  end

  def update_list_name(id, list_name)
    list = find_list(id)
    list[:name] = list_name
  end

  def create_new_todo(list_id, text)
    list = find_list(list_id)
    list[:todos] << { name: text, completed: false, id: next_todo_id(list[:todos]) }
  end

  def delete_todo_from_list(list_id, todo_id)
    list = find_list(list_id)
    list[:todos].delete_if { |todo| todo[:id] == todo_id.to_i }
  end

  def update_todo_status(list_id, todo_id, completed)
    list = find_list(list_id)
    todo = list[:todos].select { |todo| todo[:id] == todo_id.to_i }.first
    todo[:completed] = (completed == "true")
  end

  def mark_all_todos_as_completed(list_id)
    list = find_list(list_id)
    list[:todos].each do |todo|
      todo[:completed] = true
    end
  end

  private

  def next_list_id(lists)
    max = lists.map{ |list| list[:id] }.max || 0
    max + 1
  end

  def next_todo_id(todos)
    max = todos.map { |todo| todo[:id] }.max || 0
    max + 1
  end
end
