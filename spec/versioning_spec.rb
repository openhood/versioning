require File.dirname(__FILE__) + '/spec_helper'

class Chicken < ActiveRecord::Base
  has_many :chicken_children
  has_many :children, :through => :chicken_children
  versioning :only => [:name, :description, :children], :associations => :children, :counter_cache => :version_count
end
class Child < ActiveRecord::Base
  belongs_to :chicken
end
class ChickenChild < ActiveRecord::Base
  belongs_to :chicken
  belongs_to :child
end

describe Chicken do

  describe "Given a chicken called Gertrude" do

    before do
      @chicken = Chicken.new(:name => "Gertrude")
    end

    it "should be valid object" do
      @chicken.valid?.should == true
    end

    it "should have no children" do
      @chicken.children.should == []
    end

    it "should allow saving" do
      @chicken.save.should == true
    end

    it "a model ChickenVersion should be defined" do
      lambda{
        "ChickenVersion".constantize
      }.should_not raise_error(NameError)
    end

    describe "When saved first" do

      before do
        @chicken.save
      end

      it "should not create a new version" do
        @chicken.versions.should == []
        ChickenVersion.count.should == 0
      end

      it "counter cache should be zero" do
        @chicken.version_count.should == 0
      end

      it "should fill-in the group column with primary key value" do
        @chicken.main_id.should == @chicken.id
      end

    end

    describe "When created_at changed" do

      before do
        @chicken.save
        @chicken.update_attribute(:created_at, Time.now)
      end

      it "should not create a new version" do
        @chicken.save
        @chicken.versions.should == []
      end

    end

    describe "When name is changed to Joan" do

      before do
        @chicken.save
        @chicken.update_attribute(:name, "Joan")
      end

      it "should create a new version" do
        @chicken.versions.size.should == 1
      end

      it "counter cache should be 1 after reload" do
        @chicken.reload
        @chicken.version_count.should == 1
      end

      it "should create a new version with name Gertrude" do
        @chicken.versions.first.name.should == "Gertrude"
      end

      it "Gertrude should still be linked to Joan" do
        @chicken.versions.first.current_version.name.should == "Joan"
      end

    end

  end

  describe "Given a chicken called Gertrude who has 2 children" do

    before do
      @chicken = Chicken.new(:name => "Gertrude")
      @chicken.children.build(:name => "Junior")
      @chicken.children.build(:name => "Mini")
    end

    it "should allow saving" do
      @chicken.save.should == true
    end

    describe "When name is changed to Joan and she has a new child" do

      before do
        @chicken.save
        @chicken.name = "Joan"
        @chicken.children.build(:name => "Leslea")
        @chicken.save
      end

      it "should create a new version" do
        @chicken.versions.size.should == 1
      end

      it "Joan should now have 3 children" do
        @chicken.children.count.should == 3
      end

      it "Gertrude should still have 2 children" do
        @chicken.versions.first.children.count.should == 2
      end

    end

    describe "When she just loose a child" do

      before do
        @chicken.save
        @chicken.children.delete(@chicken.children.first)
        @chicken.save
      end

      it "should create a new version" do
        @chicken.versions.size.should == 1
      end

    end

  end

end