module MongoMapper
  module Associations
    class ManyDocumentsProxy < Proxy
      delegate :klass, :to => :@association
      delegate :with_scope, :to => :klass
      
      def [](index)
        load_target
        @target[index]
      end

      def find(*args)
        options = args.extract_options!
        klass.find(*args << scoped_options(options))
      end

      def paginate(options)
        klass.paginate(scoped_options(options))
      end

      def all(options={})
        find(:all, scoped_options(options))
      end

      def first(options={})
        find(:first, scoped_options(options))
      end

      def last(options={})
        find(:last, scoped_options(options))
      end

      def count(conditions={})
        klass.count(conditions.deep_merge(scoped_conditions))
      end
      alias_method :size, :count
      alias_method :length, :count

      def replace(docs)
        @target.map(&:destroy) if load_target
        docs.each { |doc| apply_scope(doc).save }
        reset
      end

      def <<(*docs)
        ensure_owner_saved
        flatten_deeper(docs).each { |doc| apply_scope(doc).save }
        reset
      end
      alias_method :push, :<<
      alias_method :concat, :<<

      def build(attrs={})
        doc = klass.new(attrs)
        apply_scope(doc)
        doc
      end

      def create(attrs={})
        doc = klass.new(attrs)
        apply_scope(doc).save
        doc
      end

      def destroy_all(conditions={})
        all(:conditions => conditions).map(&:destroy)
        reset
      end

      def delete_all(conditions={})
        klass.delete_all(conditions.deep_merge(scoped_conditions))
        reset
      end
      
      def nullify
        criteria = FinderOptions.to_mongo_criteria(scoped_conditions)
        all(criteria).each do |doc|
          doc.update_attributes self.foreign_key => nil
        end
        reset
      end
      
      def to_ary
        load_target
        if @target.is_a?(Array)
          @target.to_ary
        else
          Array(@target)
        end
      end

      protected
        def scoped_conditions
          {self.foreign_key => @owner.id}
        end

        def scoped_options(options)
          options.deep_merge({:conditions => scoped_conditions})
        end

        def find_target
          find(:all)
        end

        def ensure_owner_saved
          @owner.save if @owner.new?
        end

        def apply_scope(doc)
          ensure_owner_saved
          doc.send("#{self.foreign_key}=", @owner.id)
          doc
        end

        def foreign_key
          @association.options[:foreign_key] || @owner.class.name.underscore.gsub("/", "_") + "_id"
        end
        
      private
        def method_missing(method, *args)
          # see Rails trac #1764 for when this was added to Rails
          if @target.respond_to?(method)#|| (!klass.respond_to?(method) && Class.respond_to?(method))
            ##puts "-- from MDP#method_missing: target #{@target.inspect} (a #{@target.class}) responds to method #{method.inspect} with args #{args.inspect}"
            if block_given?
              super { |*block_args| yield(*block_args) }
            else
              super
            end
          else
            ##puts "-- from MDP#method_missing: klass #{klass} responds to method #{method.inspect} with args #{args.inspect}"
            with_scope(:conditions => scoped_conditions) do
              ##p "klass_id" => klass.object_id
              if block_given?
                klass.send(method, *args) { |*block_args| yield(*block_args) }
              else
                klass.send(method, *args)
              end
            end
          end
        end
    end
  end
end
