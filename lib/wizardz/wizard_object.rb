class Wizardz::WizardObject
  attr_reader :page_data

  def initialize(page_data)
    @page_data = page_data
  end

  def valid?
    true
  end
end
