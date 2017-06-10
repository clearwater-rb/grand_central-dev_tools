# GrandCentral::DevTools

Client-side developer tools for the [`grand_central` gem](https://github.com/clearwater-rb/grand_central).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'grand_central-dev_tools'
```

And then execute:

    $ bundle

## Usage

Add a div to your HTML document for the dev tools to render into:

```html
<div id="grand-central"></div>
```

If you have a `dev.rb` or some other development-only asset, you'll want to add it into there:

```ruby
# dev.rb
require 'grand_central/dev_tools'
require 'store' # Change this to wherever your GrandCentral store is loaded from

dev_tools = GrandCentral::DevTools.new(
  Store, # Your store object goes here. Any store type will work.
  Bowser.document['#grand-central'] # The div we added to our HTML document.
)
dev_tools.start # Actually begin monitoring the store
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/clearwater-rb/grand_central-dev_tools. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

