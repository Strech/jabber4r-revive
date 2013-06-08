# coding: utf-8
$LOAD_PATH.unshift File.expand_path("../../", __FILE__)

require "jabber4r"
Dir["spec/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  # ... dummy
end
