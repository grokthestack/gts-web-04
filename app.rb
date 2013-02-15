require 'sinatra'
require "sqlite3"

database_file = settings.environment.to_s+".sqlite3"
db = SQLite3::Database.new database_file
db.results_as_hash = true

db.execute "
	CREATE TABLE IF NOT EXISTS users (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name VARCHAR(255)
	);
";

db.execute "
	CREATE TABLE IF NOT EXISTS messages (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		message VARCHAR(255),
		user_id INTEGER
	);
";

get '/' do
	users = db.execute "SELECT users.name FROM users WHERE 1;"
	puts "USERS BEFORE: " + users.inspect
	users.sort_by! {|nameHash| nameHash["name"]}
	puts "USERS AFTER: " + users.inspect
	allMessages = db.execute("SELECT * FROM messages WHERE 1")

	@userMessageHash = Hash.new
	
	users.each do |user|
		name = user["name"]
		messages = db.execute("SELECT messages.message FROM messages
									JOIN users ON messages.user_id = users.id
									WHERE users.name = ?;", name)

		@userMessageHash[name] = messages
	end

	erb File.read('our_form.erb')
end

post '/' do
	# get name and message inputs from the fields in our_form.erb and store them
	@name = params['name']
	@message = params['message']

	# check if user name is in database already
	nameArray = db.execute("SELECT users.name FROM users WHERE users.name = ?", @name)
	if nameArray.empty?
		# insert user with name = @name into users db
		db.execute("INSERT INTO users (name) VALUES(?)", @name)
	end
	
	# fetch id of user @name
	# since an array (length 1) of hashes is returned, get first hash,
	# which contains just an 'id' key-value pair, and get the value of 'id'
	user_id = db.execute("SELECT users.id FROM users WHERE users.name = ?;", @name)[0]["id"]

	# insert @message into message db
	db.execute("INSERT INTO messages (message, user_id) VALUES(?, ?)", @message, user_id)

	erb File.read('thanks.erb')
end

get '/users/:name' do
	@name = params['name']
	@user = db.execute("SELECT users.name FROM users WHERE users.name = ?", @name)
	if @user.empty?
		return erb File.read('no_such_user.erb')
	else
		# get array of hashes that contain messages associated with user id
		@messages = db.execute("SELECT messages.message FROM messages
									JOIN users ON messages.user_id = users.id
									WHERE users.name = ?;", @name)
		return erb File.read('user_messages.erb')
	end
end

get '/users/:oldName/edit' do
	@name =  params['oldName']
	@user = db.execute("SELECT users.name FROM users WHERE users.name = ?", @name)
	if @user.empty?
		return erb File.read('no_such_user.erb')
	else
		erb File.read('change_username_form.erb')
	end
end

post '/users/:oldName/edit' do
	# this comes from the new_name html field
	@newName = params['newName']
	@oldName = params['oldName']

	db.execute("UPDATE users set name = ? WHERE users.name = ?", @newName, @oldName)

	erb File.read('edit_user_name_success.erb')
end

# Create a new user (name, password)
post '/users/' do
end

# Login the user (name, password)
post '/login' do
end