actions :set

attribute :file, :name_attribute => true
attribute :command, :kind_of => [String, Array], :required => true

def initialize(*args)
  super
  @action = :set
end

