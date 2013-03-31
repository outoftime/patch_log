# PatchLog #

PatchLog is an extension to ActiveRecord that enables versioning of text-heavy
models using `diff` and `patch`. This approach can be much more space-efficient
than simply storing a copy of each previous version.

PatchLog is mostly a proof of concept, but there's no reason it shouldn't be
usable in real life.

## Installation ##

``` ruby
gem 'patch_log'
```

## Setup ##

Let's say you want to version the `:body` field in your model:

``` ruby
class Page < ActiveRecord::Base
  include PatchLog
  patch_log :body
end
```

You will need to also create a migration making two changes:

* Add a `current_version_id` field to your `pages` table
* Add a `page_diffs` table

Like this:

``` ruby
alter_table :pages do |t|
  t.int :current_version_id
end

# You have to write SQL here because I don't think ActiveRecord migrations
# support composite primary keys
execute "
CREATE TABLE page_diffs (page_id int, version_id int, body_diff text,
PRIMARY KEY (page_id, version_id))
"
```

## Usage ##

Once you've set up your model, any time one of the `patch_log`-enabled columns
is updated, the diff will be persisted to the `page_diffs` table. You can get a
list of all previous versions with:

``` ruby
page.previous_versions
```

This will return a list of timestamps in descending order. To restore a previous
version, use:

``` ruby
page.restore_version(some_version_timestamp)
```

This will return a copy of the page with the `patch_log` fields rewinded to
their state from the specified version.

## Delimiters ##

By default, `diff` tracks changes on a line-by-line basis. You can change the
granularity of this behavior using the `patch_log_delimiter` class property,
e.g.:

``` ruby
class Page < ActiveRecord::Base
  include PatchLog
  patch_log :body
  self.patch_log_delimiter = /[[:space]]/
end
```

## What's missing ##

This library should provide migration generators and tighter ActiveRecord
integration.

Also, PatchLog shells out and uses a lot of temporary files when creating and
applying diffs. There is possibly a better way of going about this.

## Copyright ##

This software is freely distributable under the MIT license.
