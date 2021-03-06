class User < ActiveRecord::Base
  acts_as_authentic

  has_many :phone_numbers
  has_many :voicemails
  has_many :messagings
  has_many :outgoing_calls
  has_many :incoming_calls
  has_many :contacts
  has_many :profiles

  # returns the default phone to ring, if user defines multiple default phones, then pick the first one;
  # if user does not define a default, then just pick the first forwarding phone;
  # if user does not define a forwarding phone, just pick the first phone number;
  # if user does not define any phone yet, returns an error message
  def default_phone_number
    return "Please add a phone number to OpenVoice" if phone_numbers.empty?
    defaults = phone_numbers.select{ |n| n.default == true }
    return defaults.first.number unless defaults.empty?
    forwards = phone_numbers.select{ |n| n.forward == true }
    return forwards.first.number unless forwards.empty?
    return phone_numbers.first.number
  end

  # returns all the forward phone_numbers
  def forwarding_numbers
    phone_numbers.select{ |n| n.forward == true }.map(&:number)
  end
end
