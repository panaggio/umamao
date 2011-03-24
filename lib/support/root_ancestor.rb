# This module is used so that it is easy to find the most general
# ancestor inside the application for a given class. Simply do
#
#     class Root
#       include Support::RootAncestor
#
#       # ...
#
#     end
#
#     class Child < Root
#     end
#
#     Child.new.root_class == Root
#
# Right now this is mostly useful because of Topic, which has lots of
# subclasses.

module Support::RootAncestor
  def self.included(klass)
    klass.class_eval do
      @root_ancestor = klass
      class << self; attr_reader :root_ancestor; end
      extend ClassMethods
      include InstanceMethods
    end
  end

  module ClassMethods
    def inherited(subclass)
      subclass.instance_variable_set("@root_ancestor", root_ancestor)
      super
    end
  end

  module InstanceMethods
    def root_class
      self.class.root_ancestor
    end
  end
end
