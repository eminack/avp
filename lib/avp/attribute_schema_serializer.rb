module AVP
  class AttributeSchemaSerializer
    def initialize(object)
      @object = object
    end

    # columns: [{ key: 'slug', type: 'String' },{key: 'datasource', type: 'String'},
    #           { key: 'properties', type: 'Hash', columns: [{ key: 'name', type: 'String' }, { key: 'age', type: 'Integer' }]},
    #           { key: friends, type: Set, element: 'String/Boolean/Long' }]
    def self.serialize_schema
      serialize_column_schema(columns)
    end

    ###
    # returns: [
    #   {
    #    "email": { "string": "sameer@synaptic.com" },
    #     "id": { "string": "1234"},
    #     "properties": {
    #         "record": {
    #             "age": { "long": 30 },
    #             "name": { "string": "Sameer" }
    #         }
    #      },
    #     "friends": { "set": ['mansi','anurag'] }
    #   }
    # ]
    def serialize
      serialize_columns(self.class.columns)
    end

    # columns: [{ key: 'slug', type: 'String' },{key: 'datasource', type: 'String'},
    #           { key: 'properties', type: 'Hash', columns: [{ key: 'name', type: 'String' }, { key: 'age', type: 'Integer' }]},
    #           { key: friends, type: Set, element: 'String/Boolean/Long' }]
    def self.columns(columns)
      define_singleton_method(:columns) do
        columns
      end
      columns
    end

    # returns:
    # { 'type': 'String' } OR
    # { 'type': 'Boolean' } OR
    # { 'type': 'Record', 'attributes': { 'name': { 'type': 'String' }, 'age': { 'type': 'Long' }}} OR
    # { 'type': 'Set', 'element': { 'type': 'String'} }
    def self.serialize_data_schema(column)
      case column[:type]
      when 'String'
        { 'type' => 'String', 'required' => true }
      when 'Boolean'
        { 'type' => 'Boolean', 'required' => true }
      when 'Integer'
        { 'type' => 'Long', 'required' => true }
      when 'Hash'
        { 'type' => 'Record', 'attributes' => serialize_column_schema(column[:columns]), 'required' => true }
      when 'Set'
        { 'type' => 'Set', 'element' => { 'type' => column[:element] }, 'required' => true }
      end
    end

    # returns:
    # {
    #   'slug': { 'type': 'String' },
    #   'datasource': { 'type': 'Boolean' }
    #   'properties': { 'type': 'Record', 'attributes': { 'name': { 'type': 'String' }, 'age': { 'type': 'Long' }}},
    #   'friends': { 'type': 'Set', 'element': { 'type': 'String'} }
    # }
    def self.serialize_column_schema(columns)
      serialized_data = {}
      columns&.each do |column|
        key = column[:key]
        serialized_data[key.to_s] = serialize_data_schema(column)
      end
      serialized_data
    end

    private

    attr_reader :object

    def serialize_columns(columns, datum = nil)
      serialized_data = {}
      columns&.each do |column|
        attribute_name = column[:key]
        serialized_data[attribute_name.to_s] = serialize_value(attribute_name, column, datum)
      end
      serialized_data
    end

    def serialize_value(attribute_name, column, datum)
      case column[:type]
      when 'String'
        { 'string' =>  fetch_value(attribute_name, datum) }
      when 'Boolean'
        { 'boolean' => fetch_value(attribute_name, datum) }
      when 'Integer'
        { 'long' => fetch_value(attribute_name, datum) }
      when 'Hash'
        { 'record' => serialize_columns(column[:columns], fetch_value(attribute_name, datum)) }
      when 'Set'
        { 'set' => fetch_value(attribute_name, datum) }
      else
        raise "Unknown attribute type #{attribute_type}"
      end
    end

    # checks if a method is defined for attribute name in order: serializer then object
    def fetch_value(attribute_name, datum)
      if datum.present?
        datum.with_indifferent_access[attribute_name.to_sym] || datum.with_indifferent_access[attribute_name.to_s]
      elsif respond_to?(attribute_name.to_sym)
        send(attribute_name.to_sym)
      elsif object.respond_to?(attribute_name.to_sym)
        object.send(attribute_name.to_sym)
      else
        raise "Unknown attribute #{attribute_name}"
      end
    end
  end
end
