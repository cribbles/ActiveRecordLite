require 'sqlite3'

CLASS_METHODS = [
  :execute,
  :execute2,
  :get_first_row,
  :get_first_value
]

class DBConnection
  def self.db
    @db
  end

  def self.open(db_file_name)
    @db = SQLite3::Database.new(db_file_name)
    @db.results_as_hash = true
    @db.type_translation = true

    @db
  end

  class << self
    CLASS_METHODS.each do |method|
      define_method(method) do |*args|
        puts args[0]
        db.send(method, *args)
      end
    end
  end

  def self.last_insert_row_id
    db.last_insert_row_id
  end
end
