module Expose

  KNOWN_VERBS = Set.new([:get, :put, :post, :delete]).freeze

  def self.included(base)
    base.extend ExposeClassMethods
    base.send :include, ExposeInstanceMethods
    base.prepend_before_filter :requires_method_exposal_filter
  end
  
  module ExposeClassMethods
    def exposed_methods_hash
      @exposed_methods_hash ||= Hash.new
    end
    
    def expose(verb, *actions)
      @exposed_methods_hash ||= Hash.new
      verbs = case verb
      when Symbol
        [verb]
      when Array
        verb
      else
        raise "Expected symbol or array of symbols"
      end
      
      verbs.each do |verb|
        unless Expose::KNOWN_VERBS.include?(verb)
          raise "Unknown method (HTTP verb) " + verb.to_s
        end
        @exposed_methods_hash[verb] ||= Set.new
        @exposed_methods_hash[verb] += actions
      end
      
      return nil
    end
  end
  
  module ExposeInstanceMethods
    def requires_method_exposal_filter
      an = action_name.to_sym
      rm = request.method
      rm = :get if an == :head
      
      # no such method, give up and 404
      return true unless self.respond_to?(an)
      
      c = self.class
      
      while (c.respond_to?(:expose) && (c.name != "ApplicationController::Base"))
        m = c.public_instance_methods(false).map(&:to_sym)
        
        if m.include?(an) then
          # ok, a method defined here.
          s = c.exposed_methods_hash[rm]
          if (! s.nil?) && s.include?(an) then
            return true # ok, allowed
          else
            break # fail!
          end
        end
        c = c.superclass
      end
      
      render :text => "Method not allowed", :status => 405

      return false
    end
  end
end
