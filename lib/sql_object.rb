require_relative 'db_connection'
require_relative 'sql_relation'
require 'active_support/inflector'
require 'byebug'

RELATION_METHODS = [
  :all?,
  :any?,
  :delete_all,
  :empty?,
  :none?,
  :one?,
  :update_all
]

class SQLObject
  def self.columns
    DBConnection.execute2(<<-SQL).first.map(&:to_sym)
      SELECT
        *
      FROM
        #{table_name}
    SQL
  end

  def self.finalize!
    columns.each do |column|
      reader, writer = column, "#{column}="

      define_method(reader) do
        attributes[reader]
      end

      define_method(writer) do |value|
        attributes[reader] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name.tableize
  end

  def self.table_name
    @table_name ||= to_s.tableize
  end

  class << self
    RELATION_METHODS.each do |method|
      # This procedure just delegates ::any? and friends to their respective
      # SQLRelation methods.  We send define_method a stabby lambda instead
      # of a block because we can't pipe &blk arguments.

      delegation_blk = ->(*args, &blk) do
        self.all.send(method, *args, &blk)
      end

      define_method(method, delegation_blk)
    end
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL

    parse_all(results)
  end

  def self.count
    DBConnection.get_first_value(<<-SQL)
      SELECT
        COUNT(*)
      FROM
        #{table_name}
    SQL
  end

  def self.find(id)
    result = DBConnection.get_first_row(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{table_name}.id = ?
    SQL

    result ? self.new(result) : nil
  end

  def self.parse_all(attributes)
    sql_relation = SQLRelation.new(to_s.constantize)

    attributes.each do |attributes|
      sql_relation << new(attributes)
    end

    sql_relation
  end

  def self.where(params)
    SQLRelation.new(to_s.constantize).where(params)
  end

  def initialize(params = {})
    columns = self.class.columns

    params.each do |column, value|
      if !columns.include?(column.to_sym)
        raise "unknown attribute '#{column}'"
      end

      send("#{column}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    attributes[:id] ||= self.class.count + 1

    col_names = attributes.keys.map(&:to_s).join(", ")
    val_names = (["?"] * attributes.count).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{table_name} (#{col_names})
      VALUES
        (#{val_names})
    SQL
  end

  def update
    updates = attributes.keys.map { |attr| "#{attr} = ?" }.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values, attributes[:id])
      UPDATE
        #{table_name}
      SET
        #{updates}
      WHERE
        id = ?
    SQL
  end

  def save
    if attributes[:id].nil?
      insert
    else
      update
    end
  end

  private

  def table_name
    self.class.table_name
  end
end
