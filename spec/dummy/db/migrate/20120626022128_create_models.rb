class CreateModels < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :title
      t.string :first_name
      t.string :last_name
      t.string :address
      t.date   :dob
      t.string :city
      t.string :state
      t.string :zip
      t.string :phone
      t.string :email
      t.timestamps
    end

    create_table :websites do |t|
      t.string :name
      t.string :address
      t.references :user
      t.timestamps
    end

    create_table :pages do |t|
      t.references :website
    end

    create_table :sections do |t|
      t.string :type
      t.references :page
      t.string :header
      t.text :content
    end

    create_table :comments do |t|
      t.references :user
      t.references :commentable, :polymorphic => true
      t.string :name
      t.string :email
      t.text :content
    end
  end
end
