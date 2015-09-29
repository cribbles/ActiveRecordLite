require_relative 'lib/sql_object'

DEMO_DB_FILE = 'db/cats.db'
DEMO_SQL_FILE = 'db/cats.sql'

`rm '#{DEMO_DB_FILE}'`
`cat '#{DEMO_SQL_FILE}' | sqlite3 '#{DEMO_DB_FILE}'`

DBConnection.open(DEMO_DB_FILE)

class Cat < SQLObject
  # Columns: `id,` `name`, `owner_id`
  belongs_to :human, foreign_key: :owner_id
  has_one_through :house, :human, :house

  finalize!
end

class Human < SQLObject
  # Columns: `id,` `fname`, `lname`, `house_id`
  self.table_name = "humans"

  has_many :cats, foreign_key: :owner_id
  belongs_to :house

  finalize!
end

class House < SQLObject
  # Columns: `id,` `address`
  # In this case we're just specifying the defaults for this class.
  has_many :humans,
    class_name: "Humans",
    foreign_key: :house_id,
    primary_key: :id

  finalize!
end
