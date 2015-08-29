require_relative 'db_connection'
require_relative 'sql_object'

class SQLRelation
  attr_reader :klass

  def initialize(klass)
    @klass = klass
    @collection = []
  end

  def to_a
    force.collection.map { |sql_object| sql_object }
  end

  def <<(sql_object)
    raise "invalid collection object" unless sql_object.is_a?(klass)

    @collection << sql_object
  end

  def table_name
    klass.table_name
  end

  def where_params_hash
    @where_params_hash ||= {}
  end

  def where(params)
    where_params_hash.merge!(params)

    self
  end

  def any?(&blk)
    if block_given?
      to_a.any? { |*args| blk.call(*args) }
    else
      !empty?
    end
  end

  def count
    DBConnection.get_first_value(<<-SQL, *sql_params[:values])
      SELECT
        COUNT(*)
      FROM
        #{table_name}
      #{sql_params[:where]}
        #{sql_params[:params]}
    SQL
  end

  def empty?
    count == 0
  end

  def first
    ultimate_row("ASC")
  end

  def force
    results = DBConnection.execute(<<-SQL, *sql_params[:values])
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      #{sql_params[:where]}
        #{sql_params[:params]}
    SQL

    klass.parse_all(results)
  end

  def last
    ultimate_row("DESC")
  end

  def limit(num)
    results = DBConnection.execute(<<-SQL, *sql_params[:values])
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      #{sql_params[:where]}
        #{sql_params[:params]}
      LIMIT
        #{num}
    SQL

    klass.parse_all(results)
  end

  private

  attr_reader :collection

  def sql_params
    params, values = [], []

    where_params_hash.map do |attribute, value|
      slug = value.is_a?(Fixnum) ? "?" : "'?'"

      params << "#{attribute} = #{slug}"
      values << value
    end

    { params: params.join(" AND "),
      where:  (params.empty? ? "" : "WHERE"),
      values: values }
  end

  def ultimate_row(order)
    result = DBConnection.get_first_row(<<-SQL, *sql_params[:values])
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      #{sql_params[:where]}
        #{sql_params[:params]}
      ORDER BY
        id #{order}
      LIMIT
        1
    SQL

    result ? klass.new(result) : nil
  end
end
