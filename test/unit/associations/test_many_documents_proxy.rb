require 'test_helper'

class Foo
  include MongoMapper::Document
  # let's define this just in case
  #def self.some_method; end
  #def self.some_method_with_block(&block); yield; end
end

class ManyDocumentsProxyTest < Test::Unit::TestCase
  include MongoMapper::Associations
  
  def setup
    @association = Base.new(:many, :foos)
    @klass = Foo
    @association.stubs(:klass).returns(@klass)
    @owner = stub('owner', :id => 1)
    @proxy = ManyDocumentsProxy.new(@owner, @association)
  end
  
  should 'forward #with_scope to the association class' do
    @klass.expects(:with_scope).with(:conditions => 'foo')
    @proxy.with_scope(:conditions => 'foo')
  end
  
  should 'have #size as an alias for #count' do
    ManyDocumentsProxy.instance_method(:size).should == ManyDocumentsProxy.instance_method(:count)
  end
  should 'have #length as an alias for #count' do
    ManyDocumentsProxy.instance_method(:length).should == ManyDocumentsProxy.instance_method(:count)
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
    should "forward the method to the association class if it responds to the method" do
      @proxy.stubs(:scoped_conditions)
      @klass.expects(:some_method).with('foo', 'bar')
      @proxy.some_method('foo', 'bar')
    end
    should "forward the method (along with the given block) to the association class if it responds to the method" do
      @proxy.stubs(:scoped_conditions)
      @klass.expects(:some_method_with_block).with('foo', 'bar').and_a_block
      @proxy.some_method_with_block('foo', 'bar') { }
    end
  end
  
  context "converting to array" do
    should "work if target is already an array" do
      @proxy.stubs(:load_target).returns([])
      @proxy.to_ary.should == []
    end
    should "work if target is not already an array" do
      @proxy.stubs(:load_target).returns(nil)
      @proxy.to_ary.should == []
    end
  end
  
end