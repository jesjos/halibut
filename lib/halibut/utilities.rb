module Halibut
  module Utilities
    # Copied from Ruby on Rails/ActiveSupport
    def self.array_wrap(object)
      if object.nil?
        []
      elsif object.respond_to?(:to_ary)
        object.to_ary || [object]
      else
        [object]
      end
    end
  end
end
