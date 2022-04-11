require 'pg'

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "todos")
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1;"
    result = query(sql, id)
    tuple = result.first
    { id: tuple["id"], name: tuple["name"], todos: todos_for_list(tuple["id"]) }
  end

  def all_lists
    sql = "SELECT * FROM lists;"
    result = query(sql)

    result.map do |tuple|
      { id: tuple["id"], name: tuple["name"], todos: todos_for_list(tuple["id"]) }
    end
  end

  def delete_list(id)
    query("DELETE FROM todos WHERE list_id = $1;", id)
    query("DELETE FROM lists WHERE id = $1;", id)
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1);"
    query(sql, list_name)
  end

  def update_list_name(id, list_name)
    sql = "UPDATE lists SET name = $1 WHERE id = $2;"
    query(sql, list_name, id)
  end

  def create_new_todo(list_id, text)
    sql = "INSERT INTO todos (name, list_id) VALUES ($1, $2);"
    query(sql, text, list_id)
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = "DELETE FROM todos WHERE id = $1 AND list_id = $2;"
    query(sql, todo_id, list_id)
  end

  def update_todo_status(list_id, todo_id, completed)
    sql = "UPDATE todos SET completed = $1 WHERE id = $2 AND list_id = $3;"
    query(sql, completed, todo_id, list_id)
  end

  def mark_all_todos_as_completed(list_id)
    sql = "UPDATE todos SET completed = true WHERE list_id = $1;"
    query(sql, list_id)
  end

  private

  def todos_for_list(list_id)
    sql = "SELECT * FROM todos WHERE list_id = $1"
    result = query(sql, list_id)
    result.map do |tuple|
      { name: tuple["name"], completed: convert_to_boolean(tuple["completed"]), id: tuple["id"].to_i }
    end
  end

  def convert_to_boolean(t_or_f)
    t_or_f == "t"
  end
end
