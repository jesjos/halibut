require 'halibut/core/relation_map'
require 'halibut/core/link'

module Halibut::Core

  # This class represents a HAL Resource object.
  #
  # spec spec spec
  class Resource

    # All the properties set in this resource
    attr_reader :properties

    # A collection of links, grouped by relation
    attr_reader :links

    # A collection of embedded resources, grouped by relation.
    attr_reader :embedded

    # Initialize a new Resource.
    #
    # As defined in the spec, the resource SHOULD have a self link, but it
    # isn't required.
    # Also optionally, I'm toying with the idea of being able to pass in
    # properties, links and embedded resources as parameters to this method,
    # like suggested in https://github.com/locks/halibut/issues/1.
    #
    # @example Resource without self link (e.g. POSTing a new resource)
    #     resource = Halibut::Core::Resource.new
    #     resource.set_property :name,   'Halibut Rules'
    #     resource.set_property :winner, 'Tiger Blood'
    #
    # @example Resource with a self link
    #     resource = Halibut::Core::Resource.new
    #
    # @param [String] href link that will be added to the self relation.
    # @param [Hash] properties resources properties.
    # @param [Hash] links resource links.
    # @param [Hash] embedded embedded resources.
    def initialize(href=nil, properties={}, links={}, embedded={})
      @links           = RelationMap.new
      @embedded        = RelationMap.new
      @properties = {}

      add_link('self', href) if href
    end

    # Returns the self link of the resource.
    #
    # @return [String,nil] the self link of the resource
    def href
      Halibut::Utilities.array_wrap(@links['self']).map(&:href).first
    end

    # Returns the namespace associated with the name.
    #
    # @param [String] name the name for which you want to retrieve a namespace
    #                 for.
    # @return [Halibut::Core::Link]
    def namespace(name)
      @links['curies'].select { |ns| ns.name == name }.first
    end
    alias_method :ns, :namespace

    def namespaces
      @links['curies']
    end

    # Sets a property in the resource.
    #
    # @example
    #     resource = Halibut::Core::Resource.new
    #     resource.set_property :name, 'FooBar'
    #     resource.property :name
    #     # => "FooBar"
    #
    # @param [Object] property the key
    # @param [Object] value    the value
    def set_property(property, value)
      if property == '_links' || property == '_embedded'
        raise ArgumentError, "Argument #{property} is a reserved property"
      end

      tap { @properties[property] = value }
    end

    def []=(property, value)
      tap { @properties[property] = value }
    end

    # Returns the value of a property in the resource
    #
    # @example
    #     resource = Halibut::Core::Resource.new
    #     resource.set_property :name, 'FooBar'
    #     resource.property :name
    #     # => "FooBar"
    #
    # @param [String] property property
    def property(property)
      @properties.fetch(property, nil)
    end

    # Adds a namespace to the resource.
    #
    # @param [String] name The name of the namespace
    # @param [String] href The templated URI of the namespace
    def add_namespace(name, href)
      add_link('curies', href, templated: true, name: name)
    end

    # Adds link to relation.
    #
    # @example
    #     resource = Halibut::Core::Resource.new
    #     resource.add_link 'next', '/resource/2', name: 'Foo'
    #     link = resource.links['next'].first
    #     link.href
    #     # => "/resource/2"
    #     link.name
    #     # => "Foo"
    #
    # @param [String]      relation  relation
    # @param [String]      href      href
    # @param [Hash]        opts      options: templated, type, name, profile,
    #                                  title, hreflang
    def add_link(relation, href, opts={})
      @links.add relation, Link.new(href, opts)
    end

    # Embeds resource in relation
    #
    # To embed many resources, call #add_embedded_resource with each item
    #
    # @param [String]   relation relation
    # @param [Resource] resource resource to embed
    def embed_resource(relation, resource)
      @embedded.add relation, resource
    end

    # Hash representation of the resource.
    # Will ommit links and embedded keys if they're empty
    #
    # @return [Hash] hash representation of the resource
    def to_hash
      {}.merge(@properties).tap do |h|
        h['_links'] = {}.merge @links       unless @links.empty?
        h['_embedded'] = {}.merge @embedded unless @embedded.empty?
      end
    end

    # Compares two resources.
    #
    # @param  [Halibut::Core::Resource] other Resource to compare to
    # @return [true, false]                  Result of the comparison
    def ==(other)
      @properties == other.properties &&
      @links      == other.links      &&
      @embedded   == other.embedded
    end
  end
end