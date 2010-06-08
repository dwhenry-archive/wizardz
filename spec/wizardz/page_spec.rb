require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


class TestClass1 < Wizardz::Page
end
class TestClass2 < Wizardz::Page
  IDENTIFIER = :test_class
end
class TestClass3 < Wizardz::Page
  IDENTIFIER = :test_class
  def valid?(allow_nil=true); end
end

describe "Page" do

  it "calls new for each subclass" do
    page_data = {:first_state => {:value => 'test'}}
    page = Wizardz::Page::First.new
    Wizardz::Page::First.should_receive(:new).with({:value => 'test'}).and_return(page)
    Wizardz::Page.load_pages([:first_state], page_data, mock(Wizardz::Wizard, :classes => [Wizardz::Page::First]))
  end

  it "does not call subclass that do not respond to IDENTIFIER" do
    wiz_inst =  Wizardz::Wizard.new()
    TestClass1.should_not_receive(:new).with(anything)
    Wizardz::Page.load_pages([], {}, wiz_inst)
  end

  it "does not call subclass that do not exist in states array" do
    wiz_inst =  Wizardz::Wizard.new()
    TestClass1.should_not_receive(:new).with(anything)
    Wizardz::Page::First.should_not_receive(:new).with(anything)
    Wizardz::Page.load_pages([],{}, wiz_inst)
  end

  it "does not modify input/output data on get_valid_states call by default" do
    page = Wizardz::Page::First.new({})
    page.get_valid_states([:first_state, :second_state]).should == [:first_state, :second_state]
  end

  it 'does not raise an error if no initialize method is implemented' do
    lambda {TestClass2.new({})}.should_not raise_error
  end

  it "returns the page_data object" do
    page = Wizardz::Page::First.new({:value => 'test'})
    page.page_data.should == {:value => 'test'} 
  end
  context 'update' do
    it "does not raise an error if no update method implemented" do
      page = TestClass3.new({})
      lambda {page.update({:value => 'test 2'})}.should_not raise_error
    end

    it 'calls the valid? method during the update' do
      page = Wizardz::Page::First.new({})
      page.should_receive(:valid?).with(false)
      page.update({:value => 'test 2'})
    end

    it 'updates the page data element based on :dataset key from data' do
      page = Wizardz::Page::First.new({})
      page.update({:dataset => {:value => 'test 2'}})
      page.page_data.should == {:value => 'test 2'} 
    end
  end

  context 'transit wizard states' do
    it 'not raise an error if transit if not implemented' do
      page = Wizardz::Page::First.new({})
      lambda{page.transit('prev',[:first_state])}.should_not raise_error
    end

    it 'stay on the same state if next and last state' do
      page = Wizardz::Page::First.new({})
      page.transit('next',[:second_state, :first_state]).should == :first_state
    end

    it 'moves to the next state if next and not last state' do
      page = Wizardz::Page::First.new({})
      page.transit('next',[:first_state, :second_state]).should == :second_state
    end

    it 'stay on the same state if prev and first state' do
      page = Wizardz::Page::First.new({})
      page.transit('prev',[:first_state, :second_state]).should == :first_state
    end

    it 'moves to the next state if prev and not first state' do
      page = Wizardz::Page::First.new({})
      page.transit('prev',[:second_state, :first_state]).should == :second_state
    end

    it 'raise an error if current state if not in options' do
      page = Wizardz::Page::First.new({})
      lambda{page.transit('prev',[:second_state])}.should raise_error
    end
  end

end