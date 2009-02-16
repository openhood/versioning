require "versioning"

ActiveRecord::Base.class_eval do
  include Versioning
end