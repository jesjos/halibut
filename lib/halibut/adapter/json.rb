require 'multi_json'
require 'halibut/core'

module Halibut::Adapter

  # This adapter converts Halibut::Core::Resources to JSON encoded strings and back.
  #
  # @example
  #     resource = Halibut::Builder.new('http://example.com') do
  #       link "posts", '/posts'
  #       link "author", 'http://locks.io'
  #
  #       property "title", 'Entry point'
  #     end.resource
  #
  #     dumped = Halibut::Adapter::JSON.dump resource
  #     # => "{\"title\":\"Entry point\",\"_links\":{\"self\":{\"href\":\"http://example.com\"},\"posts\":{\"href\":\"/posts\"},\"author\":{\"href\":\"http://locks.io\"}}}"
  #
  #     loaded = Halibut::Adapter::JSON.load dumped
  #     resource == loaded
  #     # => true
  #
  module JSON

    # Returns an Halibut::Core::Resource from a JSON string
    #
    # @param [StringIO] json the JSON to parse
    def self.parse(json)
      data = MultiJson.load(json)
      ResourceExtractor.new(data).resource
    end

    # Returns a JSON string representation of an Halibut::Core::Resource
    def self.dump(resource)
      MultiJson.dump resource.to_hash
    end

    private

    # @deprecated Please use Halibut::Adapter::JSON.dump instead.
    def self.extended(base)
      base.extend InstanceMethods
    end

    module InstanceMethods

      # Returns a JSON representation of the resource.
      #
      # @example
      #     resource = Halibut::Core::Resource.new('/post')
      #     resource.extend(Halibut::Adapter::JSON)
      #     resource.to_json
      #     # => "{\"_links\":{\"self\":{\"href\":\"/post\"}}}"
      #
      # @return [String] a JSON representation of the resource
      #
      # @deprecated This might go.
      def to_json
        warn "[Deprecation] Don't depend on this, as it might disappear soon."
        MultiJson.dump self.to_hash
      end
    end

    # ResourceExtractor is responsible for deserializing an HAL resource
    # from the JSON representation.
    #
    # @example
    #     extractor = ResourceExtractor.new({})
    #     # => #<Halibut::Adapter::JSON::ResourceExtractor:0x007f8adb92f2a8
    #     extractor.resource
    #     # => #<Halibut::Core::Resource:0x007f8add058fb0
    #
    class ResourceExtractor

      # Straight-forward, just pass in a hash with the data you want to extract the
      # resource from.
      #
      # @example
      #     json = {"_links" => {"self" => {"href" => "http://example.com"}}}
      #     ResourceExtractor.new(json)
      #
      # @param [Hash] json data from which to extract the resource
      def initialize(data)
        @halibut = Halibut::Core::Resource.new
        @json    = data

        extract_properties
        extract_links
        extract_embedded_resources
      end

      # This method should be called when the the resource extracted is needed
      def resource
        @halibut
      end

      private
      def extract_properties
        properties = @json.reject {|k,v| k == '_links'    }
                          .reject {|k,v| k == '_embedded' }

        properties.each_pair do |property, value|
          @halibut.set_property(property, value)
        end
      end

      def extract_links
        links = @json.fetch('_links', [])

        links.each do |relation,values|
          link = ([] << values).flatten

          link.each do |attrs|
            href      = attrs.delete 'href'
            @halibut.add_link(relation, href, attrs)
          end
        end
      end

      def extract_embedded_resources
        resources = @json.fetch('_embedded', [])

        resources.each do |relation,values|
          embedded = Halibut::Utilities.array_wrap(values)
          embedded.map  {|embed| ResourceExtractor.new(embed).resource }
                  .each {|embed| @halibut.embed_resource(relation, embed) }
        end
      end
    end

    module ConvenienceMethods
      def parse_json(json_str_or_io)
        Halibut::Adapter::JSON.parse(json_str_or_io)
      end
    end
  end
end
