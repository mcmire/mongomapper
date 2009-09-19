class Address
  include MongoMapper::EmbeddedDocument
  
  key :address, String
  key :city,    String
  key :state,   String
  key :zip,     Integer
end

class Message
  include MongoMapper::Document
  
  key :body, String
  key :position, Integer
  key :_type, String
  key :room_id, String
  
  belongs_to :room
end

class Enter < Message; end
class Exit < Message;  end
class Chat < Message;  end

class Room
  include MongoMapper::Document
  
  module AccountsExtensions
    def inactive
      find(:all, :conditions => { :last_logged_in => nil })
    end
  end
  
  key :name, String
  many :messages, :polymorphic => true do
    def older
      find(:all, :conditions => { :position => {"$gt" => 5} })
    end
  end
  many :accounts, :polymorphic => true, :extend => AccountsExtensions
end

class Account
  include MongoMapper::Document
  
  key :_type, String
  key :room_id, String
  key :last_logged_in, Time
  
  belongs_to :room
end
class User < Account; end
class Bot < Account; end

class Project
  include MongoMapper::Document
  
  module PeopleExtensions
    def find_by_name(name)
      detect {|p| p.name == name }
    end
  end
  
  module CollaboratorsExtensions
    def top
      find(:first)
    end
  end
  
  key :name, String
  many :statuses do
    def open
      find(:all, :conditions => { :name => %w(New Assigned) })
    end
  end
  many :collaborators, :extend => CollaboratorsExtensions
  many :addresses do
    def find_all_by_state(state)
      # can't use select here for some reason
      find_all {|a| a.state == state }
    end
  end
  many :people, :extend => PeopleExtensions
end

class Collaborator
  include MongoMapper::Document
  key :project_id, String
  key :name, String
  belongs_to :project
end

class Status
  include MongoMapper::Document
  
  key :project_id, String
  key :target_id, String
  key :target_type, String
  key :name, String
  key :position, Integer
  
  belongs_to :project
  belongs_to :target, :polymorphic => true
end

class RealPerson
  include MongoMapper::Document
  
  key :room_id, String
  key :name, String
  
  belongs_to :room
  many :pets

  def realname=(n)
    self.name = n
  end
end

class Person
  include MongoMapper::EmbeddedDocument
  
  key :name, String
  key :child, Person
  
  many :pets
end

class Pet
  include MongoMapper::EmbeddedDocument
  
  key :name, String
  key :species, String
end

class Media
  include MongoMapper::EmbeddedDocument
  
  key :_type, String
  key :file, String
  key :visible, Boolean
end

class Video < Media
  key :length, Integer
end

class Image < Media
  key :width, Integer
  key :height, Integer
end

class Music < Media
  key :bitrate, String
end

class Catalog
  include MongoMapper::Document
  
  many :medias, :polymorphic => true do
    def visible
      # for some reason we can't use select here
      find_all {|m| m.visible? }
    end
  end
end

module TrModels
  class Transport
    include MongoMapper::EmbeddedDocument
    
    key :_type, String
    key :license_plate, String
    key :purchased_on, Date
  end

  class Car < TrModels::Transport
    include MongoMapper::EmbeddedDocument
    
    key :model, String
    key :year, Integer
  end

  class Bus < TrModels::Transport
    include MongoMapper::EmbeddedDocument
    
    key :max_passengers, Integer
  end

  class Ambulance < TrModels::Transport
    include MongoMapper::EmbeddedDocument
    
    key :icu, Boolean
  end

  class Fleet
    include MongoMapper::Document
    
    module TransportsExtension
      def to_be_replaced
        # for some reason we can't use select
        find_all {|t| t.purchased_on < 2.years.ago.to_date }
      end
    end
    
    many :transports, :polymorphic => true, :class_name => "TrModels::Transport", :extend => TransportsExtension
    key :name, String
  end
end
