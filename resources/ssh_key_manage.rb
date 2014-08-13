actions :add

attribute :item, :name_attribute => true
attribute :databag, :default => "ssh_keypairs" 

def initialize(*args)
  super
  @action = :add
end

