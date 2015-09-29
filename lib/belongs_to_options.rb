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
