require_relative 'db_connection'
require_relative 'sql_object'

module Searchable
  def where(params)
    where_params = params.map { |attr, val| "#{attr} = '#{val}'" }
                         .join(" AND ")

    results = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{where_params}
    SQL

    parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
