require 'wizardz/page'
require 'wizardz/page/first'
require 'wizardz/wizard_object'

module Wizardz
  class Wizard
    attr_reader :pages
    attr_reader :state
    attr_reader :valid_states
    attr_reader :unprocessed

    STATES=[{:id => :first_state, :class => Wizardz::Page::First}]

    def initialize(fund_data={},state=nil)
      state = self.states.first if state.nil?
      raise "Invalid State ':merge' is reservered state" if self.states.include?(:merge)
      state = state.to_sym
      raise "Invalid State Assignment: #{state}" unless self.states.include?(state)
      self.load_data(fund_data)
      @state = state
    end

    def method_missing(m, *args, &block)
      return @pages[m.to_sym] if self.states.include?(m.to_sym)
      super
    end

    def first_page?
      self.states.index(@state) <= 0
    end

    def last_page?
      self.states.index(@state) >= (self.states.size - 1)
    end

    def states
      @states ||= self.class::STATES.map{|r| r[:id]}
    end

    def classes
      @classes ||= self.class::STATES.map{|r| r[:class]}
    end

    def create
      raise "Create method must be implemented in subclass"
    end

    def update(data, direction=:next)
      return true if data.nil?
      if @pages[@state].update(data)
        @valid_states = @pages[@state].get_valid_states(@valid_states)
        @state = @pages[@state].transit(direction, @valid_states)
      else
        @state = @pages[@state].transit(direction, @valid_states) if direction.to_sym == :prev
        return false
      end
      return true
    end

    protected
    def load_data(fund_data)
      @valid_states = fund_data[:valid_states] || self.states
      @unprocessed = fund_data[:unprocessed] || self.states
      @state ||= self.states.first
      @pages = Page.load_pages(self.states, fund_data, self)
    end

    public
    def save_data
      results = {}
      @valid_states.each do |state|
        results[state] = @pages[state].page_data if @pages[state].respond_to?(:page_data)
      end
      results[:valid_states] = @valid_states
      results[:unprocessed] = @unprocessed.clone
      results[:unprocessed].delete(@state)
      results
    end

    def get_page
      @pages[@state].page_data
    end

    def get_page_object
      @pages[@state].page_object
    end

    def partial
      @pages[@state].partial
    end
  end
end
