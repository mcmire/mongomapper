module MongoMapper #:nodoc:
  module Scopes
    def self.included(base)
      base.extend(ClassMethods)
      class << base
        alias_method_chain :find_every, :scopes
      end
    end
    
    module ClassMethods
    protected
      # tested
      def with_scope(options = {}, action = :merge, &block)
        merged_options = merge_find_options(current_scope, options, action)
        self.scopes << merged_options
        yield
      ensure
        self.scopes.pop
      end

      def scopes
        Thread.current[:"#{self}_scopes"] ||= []
      end

      def current_scope
        scopes.last || {}
      end
      
      # tested
      def merge_find_options(current_scope, options, action)
        merged_options = options.dup
        (current_scope.keys + options.keys).uniq.each do |key|
          merge = current_scope[key] && options[key]
          if key == :conditions && merge
            merged_options[key] = current_scope[key].deep_merge(options[key])
          else
            merged_options[key] = options[key] || current_scope[key]
          end
        end
        merged_options
      end
      
    private
      def find_every_with_scopes(options)
        merged_options = merge_find_options(options, current_scope, :merge)
        find_every_without_scopes(merged_options)
      end
    end
  end
end