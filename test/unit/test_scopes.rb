require 'test_helper'

class Foo
  include MongoMapper::Document
end

class ScopesTest < Test::Unit::TestCase
  def setup
    Foo.publicize_methods!
    Foo.metaclass.publicize_methods!
  end
  def teardown
    Foo.unpublicize_methods!
    Foo.metaclass.unpublicize_methods!
  end
  
  context '.with_scope' do
    should "create a new scope using merge_find_options" do
      Foo.expects(:current_scope).returns(:conditions => {:baz => 'quux'})
      Foo.expects(:merge_find_options).with({:conditions => {:baz => 'quux'}}, {:conditions => {:foo => 'bar'}}, :merge)#.returns(:whatever => 'whatever')
      Foo.with_scope(:conditions => {:foo => 'bar'}) { }
    end
    should "add the scope to the scopes array during execution of the block and pop it off afterward" do
      Foo.stubs(:current_scope)
      Foo.stubs(:merge_find_options).returns(:whatever => 'whatever')
      Foo.scopes.should == []
      Foo.with_scope({}) do
        Foo.scopes.should == [{:whatever => 'whatever'}]
      end
      Foo.scopes.should == []
    end
    should "return the return value of the block" do
      Foo.stubs(:current_scope)
      Foo.stubs(:merge_find_options)
      Foo.with_scope({}) { "foo" }.should == "foo"
    end
  end
  
  context '.merge_find_options' do
    should "current scope options are merged with different given options" do
      merged = Foo.merge_find_options({:foo => 'bar'}, {:baz => 'quux'}, :merge)
      merged.should == {:foo => 'bar', :baz => 'quux'}
    end
    should "current scope conditions are merged with same given conditions" do
      merged = Foo.merge_find_options({:conditions => {:foo => 'bar'}}, {:conditions => {:baz => 'quux'}}, :merge)
      merged.should == {:conditions => {:foo => 'bar', :baz => 'quux'}}
    end
    should "current scope conditions are merged with same given conditions even if nested arbitrarily deep" do
      merged = Foo.merge_find_options({:conditions => {:foo => {:bar => {:quux => 'blargh'}}}}, {:conditions => {:foo => {:bar => {:zing => 'zang'}}}}, :merge)
      merged.should == {:conditions => {:foo => {:bar => {:quux => 'blargh', :zing => 'zang'}}}}
    end
    should "current scope options that are not conditions are overwritten by same given options" do
      merged = Foo.merge_find_options({:foo => "zing"}, {:foo => "zang"}, :merge)
      merged.should == {:foo => "zang"}
      merged = Foo.merge_find_options({:foo => {:bar => 'baz'}}, {:foo => {:quux => 'blargh'}}, :merge)
      merged.should == {:foo => {:quux => 'blargh'}}
    end
  end
  
  #context 'finding within a scope' do
  #  should 'inherit the conditions in the scope' do
  #    Foo.collection.expects(:find).with({:foo => 'bar'}, {:sort => nil, :limit => 0, :fields => nil, :offset => 0})
  #    Foo.with_scope(:find => {:conditions => {:foo => 'bar'}}) { Foo.find(:all) }
  #  end
  #end
end