# ActiveRecordLite

## Summary

ActiveRecordLite is an ORM that maps SQLite queries onto Ruby objects. It aims
to provide an austere, yet full-featured alternative to ActiveRecord without all
the overhead.

## Demo

1) Clone the repo
2) Head into `irb` or `pry`
3) `load './demo.rb'`
4) Go wild (using [`demo.rb`](./demo.rb) as a reference)


## Libraries

- SQLite3 (gem)
- ActiveSupport::Inflector

## Features

- Replicates core functionality of ActiveRecord::Base and ActiveRecord::Relation
(as [`SQLObject`](/lib/sql_object.rb) and
[`SQLRelation`](/lib/sql_relation.rb))
- Super friendly API - most SQLObject and SQLRelation enumerative methods will
accept params or a block as an argument
- SQLRelation search parameters are stackable and lazily-evaluated - i.e.
`Cat.all.where(name: "Rocco").where(owner_id: 2)` won't fire off a SQL query
until you call `#count`, `#force`, `#limit`, etc.

## API

SQLObject provides a few of your favorite ActiveRecord associations:

- `has_many`
- `belongs_to`
- `has_one_through`

SQLObject provides all your favorite ActiveRecord methods:

- `::count`
- `::find`
- `::where`
- `#save`
- `#create`
- `#update`
- `#destroy`

SQLRelation provides all your favorite `Enumerable` methods:

- `#all?`
- `#any?`
- `#count`
- `#empty?`
- `#first`
- `#last`
- `#none?`
- `#one?`

SQLObject [delegates enumerable methods](/lib/sql_object.rb#L53) to SQLRelation
(e.g. `Cat.any?` will iterate over the entire `Cat` collection)

## How It Works

SQLObject and SQLRelation make use of an instance of
[`DBConnection`](/lib/db_connection.rb), which provides a simple interface for
accessing SQLite::Database instance methods like `#execute`, `#get_first_row`,
`#last_insert_row_id`, etc.

## Notes

ActiveSupport::Inflector isn't a hard dependency; it's only really used for
[`#camelcase`](/lib/has_many_options.rb#L4) and
[`#underscore`](/lib/has_many_options.rb#L5) (to provide sensible `class_name`
and `foreign_key` defaults for has_many relationships).

If you _really_ want to trim overhead, you can get away with declaring options
for these manually in your association definitions.

## License

ActiveRecordLite is released under the [MIT License](/LICENSE).

---
Developed by [Chris Sloop](http://chrissloop.com)
