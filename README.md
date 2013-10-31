# Scheherazade

With Sheherazade's imagination and storytelling skills, fixtures can be as entertaining as the "Arabian Nights".

## Goals

Scheherazade

* imagines plausible characters (creates valid objects automatically)
* keeps track of her story (reuse objects within a given context)
* isn't wearing much (minimal DSL, no `instance_eval`)

## Simple Example

    # Say we have a model like:
    class Department
      belongs_to :company
      has_many :employees
      validates_presence_of :company, :name
    end

    # Without any configuration, if we write in a test:
    story.imagine(Department) # creates a Department,
                              # with a default name,
                              # associated to a new Company
    story.imagine(Department) # creates another Department
                              # with another name
                              # and associated to the same Company

## Features

For FactoryGirl (or Machinist) users: a Factory (or Blueprint) corresponds loosely to a Character

### Characters (Models)

Scheherazade creates ActiveRecord objects. The types of objects are called a *character*. A generic character could be a `User` (or equivalently `:user`) or there could be more specialized characters (say `:admin`).

All your models have a default character type; you can use the class directly or the corresponding symbol. Specialized characters must be defined within the current story before they can be used.

### Context (Story)

The current story holds:

* information on how to build characters
* the last built character (called the current character)
* any options you want

Scheherazade can tell nested stories and all this information is inherited.

### Automatic objects (Characters)

Scheherazade can be setup to generate attributes for any model. She will also by default generate values for attributes that are needed.

If the object imagined is not valid, she will try to makeup values for the attributes that have errors (e.g. because of a `validates_presence_of` with a condition that is `true`)

By default, assocations will reuse objects within the current story. For example, two imagined comments will automatically be about the current blog and posted by the current user.

### Logging

Scheherazade is meant to testing and has a logging feature that makes it easier to know what's going on. Turn it on with `Scheherazade.logger.on`

## Documentation

The main class is `Story` and there are 2 important methods: `Story#imagine` and `Story#fill`. `Story#get` is a simple shorthand to get the current character or create it if there isn't any.

## Complete example

    class User
      belongs_to :blog
      validates_presence_of :first_name, :last_name
    end

    class Blog
      has_many :users
      has_one :admin, :class_name => "User", :condition => {:admin => true}
      validates_presence_of :admin

      has_many :posts
    end

    story.instance_eval do
      fill User, :email do
        fill :admin, :admin => true,
             :nickname => ->(user, sequence){"The boss #{sequence}"}
      end

      fill Blog, :posts
    end

## Why? Scheherazade vs FactoryGirl vs Machinist

FactoryGirl and Machinist are DSLs to create ActiveRecord objects.

Both make it tedious to deal with nested structures. Example:

    #          / Location - Building - Product
    # Company {
    #          \ Department — Employee

    company = FactoryGirl.create(:company)
    location = FactoryGirl.create(:location, :company => company)
    building = FactoryGirl.create(:building, :location => location)
    product = FactoryGirl.create(:product, :building => building)
    department = FactoryGirl.create(:department, :company => company)
    employee = FactoryGirl.create(:employee, :department => department)

Since Scheherazade reuses the characters she invents, the above example can be written:

    product = story.imagine Product
    employee = story.imagine Employee

Moreover, the above two lines can often be skipped altogether and by replacing the few instances of `product` by `story.get(Product)` which will return the current Product (and imagine one when called for the first time).

FactoryGirl is also terrible for dealing with `has_many` associations. Scheherazade is clever about these.

FactoryGirl needs all factories to be created explicitly, and all attributes to be generated must also be explictly defined. Scheherazade uses convention over configuration.

## Installation

Add this line to your application's Gemfile:

    gem 'scheherazade'

And then execute:

    $ bundle

To avoid pollution from one test/spec to another, you should start and end a story before each. For example with Rspec:

    RSpec.configure do |config|
      config.before(:each) do
        story.begin
      end

      config.after(:each) do
        story.end
      end

Not sure if future versions should probably support that out of the box...?

## To do

Configurable automatic attributes
Finish support for associations with integers/arrays
Finish doc
Finish specs

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
