require 'test_helper'

class ProxyTest < Test::Unit::TestCase
  include MongoMapper::Associations
  
  class SomeProxy < Proxy
    def find_target; []; end
  end
  
  def setup
    @association = Base.new(:many, :whatever)
    @klass = stub('klass')
    @association.stubs(:klass).returns(@klass)
    @owner = stub('owner', :id => 1)
    @proxy = SomeProxy.new(@owner, @association)
  end
  
  context "when calling a missing method on the association" do
    setup do
      @target = []
      @proxy.stubs(:find_target).returns(@target)
      @proxy.reload_target
    end
    should "forward the method to the target if it responds to the method" do
      @target.expects(:some_method)
      @proxy.some_method
    end
    should "forward the method to the target (along with the given block) if it responds to the method" do
      @target.expects(:some_method_with_block).with_a_block
      @proxy.some_method_with_block { }
    end
    should "crash if the target doesn't respond to the method" do
      lambda { @proxy.nonexisting_method }.should raise_error(NoMethodError)
    end
  end
  
end

