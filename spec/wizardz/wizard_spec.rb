require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class TestClassWiz < Wizardz::Page
  IDENTIFIER = :test_class_wiz
  def page_object
    [Wizardz::WizardObject.new('aaa'), Wizardz::WizardObject.new('nnn')]
  end
end

class ErrorWiz < Wizardz::Wizard
  STATES=[{:id => :merge, :class => Wizardz::Page::First}]
end

class StateRedefWiz < Wizardz::Wizard
end

describe "Wizard" do

  it "has minimum of 0 parameters on creation" do
    lambda{Wizardz::Wizard.new()}.should_not raise_error
  end

  it "has a two optional parameters" do
    lambda{Wizardz::Wizard.new({}, :first_state)}.should_not raise_error
  end

  it "2nd paramter must be a member of 'states'" do
    lambda{Wizardz::Wizard.new({}, :invalid_state)}.should  raise_error
  end

  it "raises an error if identifier of :merge is used any Page's" do
    lambda{ErrorWiz.new()}.should  raise_error
  end

  it 'initialises valid states from params' do
    wiz = Wizardz::Wizard.new({:valid_states => [:first_state, :second_state]})
    wiz.valid_states.should == [:first_state, :second_state]
  end

  it 'initialises valid states to default value' do
    StateRedefWiz.class_eval("def states; return [:first_state];end")
    wiz = StateRedefWiz.new()
    wiz.valid_states.should == [:first_state]
  end

  it 'initialises unprocessed states from params' do
    wiz = Wizardz::Wizard.new({:unprocessed => [:first_state, :second_state]})
    wiz.unprocessed.should == [:first_state, :second_state]
  end

  it 'initialises unprocessed states to default value' do
    StateRedefWiz.class_eval("def states; return [:first_state];end")
    wiz = Wizardz::Wizard.new()
    wiz.unprocessed.should == [:first_state]
  end

  it 'initialises current state from params' do
    #TODO:: could this be a stub??
    StateRedefWiz.class_eval('def states; return [:first_state,:second_state]; end')
    wiz = StateRedefWiz.new({}, :second_state)
    wiz.state.should == :second_state
  end

  it 'initialises current_state states to default value' do
    wiz = StateRedefWiz.new()
    wiz.state.should == :first_state
  end

  it 'initialises the fund_page objects from params' do
    setup_data = {:first_state => {:value => 'test'}}
    Wizardz::Page.should_receive(:load_pages).with([:first_state, :second_state], setup_data,anything)
    wiz = StateRedefWiz.new(setup_data)
  end

  it 'initialises the fund_page to default value' do
    Wizardz::Page.should_receive(:load_pages).with([:first_state, :second_state],{},anything)
    wiz = StateRedefWiz.new()
  end

  it 'returns the data_object to save from default values' do
    wiz = StateRedefWiz.new()
    wiz.save_data.should == {:first_state=>{},
                             :unprocessed=>[:second_state],
                             :states=>[:first_state, :second_state]}
  end

  it 'returns the data_object to save from default values' do
    wiz = StateRedefWiz.new({:first_state => {:value => 'test'}})
    wiz.save_data.should ==  {:first_state=>{:value=>"test"},
                              :unprocessed=>[:second_state],
                              :states=>[:first_state, :second_state]}
  end

  it 'returns the view partial for the wizard' do
    wiz = StateRedefWiz.new({:first_state => {:value => 'test'}})
    wiz.partial.should == 'first_state'
  end

  it 'returns the current page data' do
    wiz = StateRedefWiz.new({:first_state => {:value => 'test'}})
    wiz.pages.inspect
    wiz.get_page.should == {:value => 'test'}
  end

  it 'returns the current page data object' do
    wiz = StateRedefWiz.new({:first_state => {:value => 'test'}})
    obj = wiz.get_page_object
    obj.is_a?(Wizardz::WizardObject).should be_true
    obj.page_data.should == {:value => 'test'} 
  end

  context 'return an array from page object' do
    before(:each) do
      StateRedefWiz.class_eval("def states; return [:first_state,:test_class_wiz];end")
      StateRedefWiz.class_eval("def classes; return [Wizardz::Page::First,TestClassWiz];end")
    end

    it 'returns an Array object when page object evals to an array' do
      wiz = StateRedefWiz.new({:valid_states => [:test_class_wiz],:unprocessed => [:test_class_wiz]}, :test_class_wiz)
      wiz.get_page_object.is_a?(Array).should be_true
    end

    it 'does not raise an error with page object an array and unprocessed' do
      wiz = StateRedefWiz.new({:valid_states => [:test_class_wiz],:unprocessed => [:test_class_wiz]}, :test_class_wiz)
      lambda{wiz.get_page_object}.should_not raise_error
    end

    it 'does not raise an error with page object an array and not unprocessed' do
      wiz = StateRedefWiz.new({:valid_states => [:test_class_wiz],:unprocessed => []}, :test_class_wiz)
      lambda{wiz.get_page_object}.should_not raise_error
    end
  end

  context 'update function' do
    it 'does not call the update code if a the data passed in is nil' do
      wiz = StateRedefWiz.new
      page = wiz.pages[wiz.state]
      page.should_not_receive(:update)
      wiz.update(nil)
    end

    it 'calls the update code if a the data passed in is not nil' do
      wiz = StateRedefWiz.new
      page = wiz.pages[wiz.state]
      page.should_receive(:update).and_return(false)
      wiz.update(1)
    end

    it 'calls get_valid_states and transit if update is true' do
      wiz = StateRedefWiz.new
      page = wiz.pages[wiz.state]
      page.stub!(:update).and_return(true)
      page.should_receive(:get_valid_states).and_return([])
      page.should_receive(:transit).and_return(:first_state)
      wiz.update(1)
    end

    it 'does not calls get_valid_states or transit if update is false' do
      wiz = StateRedefWiz.new
      page = wiz.pages[wiz.state]
      page.stub!(:update).and_return(false)
      page.should_not_receive(:get_valid_states)
      page.should_not_receive(:transit)
      wiz.update(1)
    end
  end
#  it 'return true for the first_look? value (indicates if page should be validated)' do
#    wiz = Wizardz::Wizard.new({:unprocessed => [:first_state]})
#    wiz.first_look?.should be_true
#  end
#
#  it 'return false for the first_look? value (indicates if page should be validated)' do
#    wiz = Wizardz::Wizard.new({:unprocessed => []})
#    wiz.first_look?.should be_false
#  end
end