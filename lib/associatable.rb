require_relative 'searchable'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.to_s.constantize
  end

  def table_name
    model_class.table_name
  end

  def initialize(options)
    associations = { primary_key: :id }
    associations.merge!(options)
    associations.each { |assoc, value| send("#{assoc}=", value) }
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    associations = {
      class_name: name.to_s.capitalize,
      foreign_key: "#{name}_id".to_sym
    }

    associations.merge!(options)
    super(associations)
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    associations = {
      class_name: name.to_s.camelcase.singularize,
      foreign_key: "#{self_class_name.to_s.downcase.underscore}_id".to_sym
    }

    associations.merge!(options)
    super(associations)
  end
end

module Associatable
  def assoc_options
    @assoc_options ||= {}
  end

  def belongs_to(name, options = {})
    define_method(name) do
      association = BelongsToOptions.new(name, options)
      self.class.assoc_options[name] = association

      model = association.model_class
      primary_key = association.primary_key
      foreign_key = association.foreign_key
      where_params = { primary_key => self.send(foreign_key) }

      model.where(where_params).first
    end
  end

  def has_many(name, options = {})
    define_method(name) do
      association = HasManyOptions.new(name, self.class, options)
      self.class.assoc_options[name] = association

      model = association.model_class
      primary_key = association.primary_key
      foreign_key = association.foreign_key
      where_params = { foreign_key => self.send(primary_key) }

      model.where(where_params)
    end

    def has_one_through(name, through_name, source_name)
      through_options = assoc_options[through_name]

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
end

class SQLObject
  extend Associatable
end
