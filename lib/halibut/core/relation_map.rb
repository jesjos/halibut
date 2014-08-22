module Halibut::Core

  # This is an abstract map with behaviour specific to HAL.
  #
  # spec spec spec
  class RelationMap
    extend Forwardable

    def_delegators :@relations, :empty?, :==

    def initialize(options = {})
      @relations = {}
    end

    # Adds an object to a relation.
    # Keeps track of single object relations for the purpose of serialization to json.
    # But for ease of use, relations will be returned as arrays.
    #
    # If the relation doesn't exist, the relation will point to the object.
    # If the relation exists and is an array, the object is added to the array.
    # If the relation exists and is a single object,
    # the existing object and the incoming object are wrapped in an array.
    #
    # @example
    #     relations = RelationMap.new
    #     relations.add 'self', Link.new('/resource/1')
    #     relations['self']
    #     # => [#<Halibut::Core::Link:0x007fa0ca5b92b8 @href=\"/resource/1\",
    #          @options=#<Halibut::Core::Link::Options:0x007fa0ca5b9240
    #          @templated=nil, @type=nil, @name=nil, @profile=nil,
    #          @title=nil, @hreflang=nil>>]
    #     relations.to_hash
    #     # => { 'self' => { 'href' => '/resource/1'} }
    #
    # @param [String] relation relation that the object belongs to
    # @param [Object] item     the object to add to the relation
    def add(relation, item)
      validate_item!(item)
      if @relations.has_key?(relation)
        add_to_existing(relation, item)
      else
        set(relation, item)
      end
    end


    # Sets an object to a relation. Overwrites previous relation.
    #
    # @param [String] relation  relation that the object belongs to
    # @param [Object] item      the object to set to the relation
    def set(relation, item)
      validate_item!(item)
      @relations[relation] = item
    end


    # Always returns nil or an array
    def [](relation)
      Halibut::Utilities.array_wrap(@relations[relation]) if @relations.has_key?(relation)
    end


    # If the key is found, wrap it in an array.
    # Otherwise, fall back to normal fetch behaviour.
    def fetch(*args, &block)
      key = args.first
      if value = @relations[key]
        Halibut::Utilities.array_wrap(value)
      else
        @relations.fetch(*args, &block)
      end
    end

    # Returns a hash corresponding to the object.
    #
    # RelationMap doesn't just return @relations because it needs to convert
    # correctly when a relation only has a single item.
    #
    # @return [Hash] relation map in hash format
    def to_hash
      @relations.each_with_object({}) do |(rel,val), obj|
        rel = rel.to_s
        if val.is_a?(Array)
          hashed_val = val.map(&:to_hash)
        else
          hashed_val = val.to_hash
        end
        obj[rel] = hashed_val
      end
    end

  private

    def validate_item!(item)
      valid = if item.is_a?(Array)
                item.all? {|sub_item| sub_item.respond_to?(:to_hash) }
              else
                item.respond_to?(:to_hash)
              end
      unless valid
        raise ArgumentError, 'only items that can be converted to hashes with #to_hash are permitted'
      end
    end

    def add_to_existing(relation, item)
      current = @relations[relation]
      if current.respond_to?(:<<)
        Halibut::Utilities.array_wrap(item).map do |subitem|
          @relations[relation] << subitem
        end
      else
        @relations[relation] = [current, item]
      end
    end

  end
end
