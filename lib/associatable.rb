require_relative 'assoc_options'
require_relative 'belongs_to_options'
require_relative 'has_many_options'
require_relative 'sql_relation'
require 'active_support/inflector'

module Associatable
  def assoc_options
    @assoc_options ||= {}
  end

  def belongs_to(name, options = {})
    association = BelongsToOptions.new(name, options)
    self.assoc_options[name] = association

    define_method(name) do
      model = association.model_class
      primary_key = association.primary_key
      foreign_key = association.foreign_key
      where_params = { primary_key => self.send(foreign_key) }

      model.where(where_params).first
    end
  end

  def has_many(name, options = {})
    association = HasManyOptions.new(name, self.class, options)
    self.assoc_options[name] = association

    define_method(name) do
      model = association.model_class
      primary_key = association.primary_key
      foreign_key = association.foreign_key
      where_params = { foreign_key => self.send(primary_key) }

      model.where(where_params)
    end
  end

  def has_one_through(name, through_name, source_name)
    through_options = self.assoc_options[through_name]

    define_method(name) do
      source_options = through_options.model_class.assoc_options[source_name]

      through = through_options.model_class.table_name
      source = source_options.model_class.table_name

      through_foreign = through_options.foreign_key
      through_primary = through_options.primary_key
      source_foreign = source_options.foreign_key
      source_primary = source_options.primary_key

      result = DBConnection.execute(<<-SQL, send(through_foreign)).first
        SELECT
          #{source}.*
        FROM
          #{source}
        JOIN
          #{through}
        ON
          #{through}.#{source_foreign} = #{source}.#{source_primary}
        WHERE
          #{through}.#{through_primary} = ?
      SQL

      source_options.model_class.new(result)
    end
  end
end
