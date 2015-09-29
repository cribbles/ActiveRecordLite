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
