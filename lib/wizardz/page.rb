  #require File.dirname(__FILE__) + '/page/fund_general'

module Wizardz
  class Page
    attr_reader :page_data
    attr_accessor :wizard_inst

    def self.load_pages(states, page_data, wizard_inst)
      return_val = {}
      wizard_inst.classes.each do |class_obj|
        return_val.merge!(self.subclass_element(class_obj,page_data, states, wizard_inst))
      end
      return_val
    end

    def self.subclass_element(class_obj, page_data,states,wizard_inst)
      id = class_obj::IDENTIFIER rescue nil
      return {} if id.nil? or !states.include?(id)

      obj = class_obj.new(page_data[id] || {})
      obj.wizard_inst = wizard_inst
      {id => obj}
    end


    def valid?(allow_nil=true)
      return allow_nil if @page_data.nil?
      self.get_object.valid?
    end

    def page_object
      obj = self.get_object
      obj.valid? unless @wizard_inst.unprocessed.include?(self.identifier)
      obj
    end

    def get_valid_states(states)
      states
    end

    def initialize(data={})
      @page_data = data || {}
    end

    def partial
      self.class::PARTIAL rescue "#{self.identifier.to_s}"
    end

    def page_data
      @page_data
    end

    def update(data)
      @page_data = data[:dataset]
      self.valid?(false)
    end

    def transit(direction, states)
      pos = states.index(self.identifier)
      raise 'Invalid States list' if pos.nil?
      pos += 1 if direction == 'next' and pos < states.size - 1
      pos -= 1 if direction == 'prev' and pos > 0
      states[pos]
    end

    protected
    def identifier
      self.class::IDENTIFIER rescue nil
    end

    def get_object
      WizardObject.new(@page_data)
    end
  end
end
