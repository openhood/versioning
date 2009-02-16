ActiveRecord::Schema.define(:version => 0) do
  create_table :chickens, :force => true do |t|
    t.string :name
    t.string :description
    t.integer :main_id
    t.string :type
    t.timestamps
  end
  create_table :children, :force => true do |t|
    t.integer :id
    t.string :name
  end
  create_table :chicken_children, :force => true do |t|
    t.integer :chicken_id
    t.string :child_id
  end
end