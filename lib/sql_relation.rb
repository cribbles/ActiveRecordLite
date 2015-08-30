require_relative 'db_connection'
require_relative 'sql_object'

class SQLRelation
  attr_reader :klass

  def initialize(klass)
    @klass = klass
    @collection = []
  end

  def to_a
    dup.force.collection
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

  def all?(params = nil, &blk)
    raise "block sent with params" if params && block_given?

    if block_given?
      to_a.all? { |*args| blk.call(*args) }
    elsif params
      dup.where(params).count == count
    else
      to_a.all? { |obj| sql_object }
    end
  end

  def any?(params = nil, &blk)
    raise "block sent with params" if params && block_given?

    if block_given?
      to_a.any? { |*args| blk.call(*args) }
    elsif params
      dup.where(params).count > 0
    else
      !empty?
    end
  end

  def count
    return collection.count if where_params_hash.empty?

    DBConnection.get_first_value(<<-SQL, *sql_params[:values])
      SELECT
        COUNT(*)
      FROM
        #{table_name}
      #{sql_params[:where]}
        #{sql_params[:params]}
    SQL
  end

  def delete_all(params = nil)
    if params.nil?
      deleted = klass.all
      where = nil
    else
      deleted = where(params).force
      rows = deleted.to_a.map(&:id).join(", ")
      where = "WHERE id IN (#{rows})"
    end

    DBConnection.execute(<<-SQL)
      DELETE FROM #{table_name} #{where}
    SQL

    deleted
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

    parse_all(results)
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

    parse_all(results)
  end

  def none?(params = nil, &blk)
    raise "block sent with params" if params && block_given?

    if block_given?
      to_a.none? { |*args| blk.call(*args) }
    elsif params
      dup.where(params).empty?
    else
      empty?
    end
  end

  def one?(params = nil, &blk)
    raise "block sent with params" if params && block_given?

    if block_given?
      to_a.one? { |*args| blk.call(*args) }
    elsif params
      dup.where(params).one? { |*args| blk.call(*args) }
    else
      count == 1
    end
  end

  def update_all(params)
    update_keys = params.keys.map { |attr| "#{attr} = ?" }.join(", ")
    update_values = params.values
    rows = force.to_a.map(&:id).join(", ")

    DBConnection.execute(<<-SQL, *update_values)
      UPDATE
        #{table_name}
      SET
        #{update_keys}
      WHERE
        id IN (#{rows})
    SQL

    force
  end

  protected
  attr_reader :collection

  private

  def parse_all(attributes)
    klass.parse_all(attributes).where(where_params_hash)
  end

  def sql_params
    params, values = [], []

    where_params_hash.map do |attribute, value|
      params << "#{attribute} = ?"
      values << value
    end

    { params: params.join(" AND "),
      where:  (params.empty? ? nil : "WHERE"),
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
