actions :create

attribute :name, :name_attribute => true
attribute :password, :required => true

def initialize(*args)
  super
  @action = :create
end
