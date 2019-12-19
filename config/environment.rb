# Load the Rails application.
require_relative 'application'

db_acc = File.join(Rails.root, 'config', 'database_acc.rb')
load(db_acc) if File.exists?(db_acc)

# Initialize the Rails application.
Rails.application.initialize!
