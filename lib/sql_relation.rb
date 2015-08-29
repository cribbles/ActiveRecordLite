require_relative 'db_connection'
require_relative 'sql_object'

class SQLRelation
  attr_reader :klass

  def initialize(klass)
    @klass = klass
    @collection = []
  end

  def to_a
    collection.map { |sql_object| sql_object }
  end

  def <<(sql_object)
    raise "invalid collection object" unless sql_object.is_a?(klass)

    @collection << sql_object
  end

  def table_name
    klass.table_name
  end

  def where_values
    @where_values ||= {}
  end

  def where(params)
    where_values.merge!(params)

    self
  end

  def force
    params, values = where_params

    results = DBConnection.execute(<<-SQL, *values)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{params}
    SQL

    klass.parse_all(results)
  end

  def count
    params, values = where_params

    DBConnection.get_first_value(<<-SQL, *values)
      SELECT
        COUNT(*)
      FROM
        #{table_name}
      WHERE
        #{params}
    SQL
  end

  def limit(num)
    params, values = where_params

    results = DBConnection.execute(<<-SQL, *values)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{params}
      LIMIT
        #{num}
    SQL

    klass.parse_all(results)
  end

  def first
    params, values = where_params

    result = DBConnection.get_first_row(<<-SQL, *values)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{params}
      LIMIT
        1
    SQL

    result ? klass.new(result) : nil
  end

  private

  attr_reader :collection

  def where_params
    params, values = [], []

    where_values.map do |attribute, value|
      slug = value.is_a?(Fixnum) ? "?" : "'?'"

      params << "#{attribute} = #{slug}"
      values << value
    end

    [params.join(" AND "), values]
  end
end
