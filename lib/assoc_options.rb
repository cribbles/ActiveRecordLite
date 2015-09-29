class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    Object.const_get(class_name.to_s)
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
