require 'sinatra'
require "sqlite3"

database_file = settings.environment.to_s+".sqlite3"
db = SQLite3::Database.new database_file
db.results_as_hash = true
db.execute "
	CREATE TABLE IF NOT EXISTS guestbook (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name_id INTEGER,
		message VARCHAR(255)
	);
";

db.execute "
	CREATE TABLE IF NOT EXISTS users (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name VARCHAR(255)
	);
";

get '/' do
	@messages = db.execute(
		"SELECT * FROM guestbook
		 JOIN users ON name_id = users.id
		"
	)
	erb File.read('our_form.erb')
end

get '/users/:name/edit' do
	@name = params['name']
	result = db.execute (
		"SELECT id FROM users WHERE name = '#{@name}'"
	)
	@name_found = result.length
	erb File.read('user_name.erb')
end

get '/users/:name' do
	@name = params['name']
	result = db.execute (
		"SELECT id FROM users WHERE name = '#{@name}'"
	)
	@name_found = result.length
	if result.length != 0
		id = result.shift['id']
		@messages = db.execute (
			"SELECT * FROM guestbook 
			 JOIN users ON name_id = users.id
			 WHERE name_id = '#{id}'
			"
		)
	end
	erb File.read('users_posts.erb')
end

get '/users/' do
	name = params['name']
	redirect "/users/"+name if name
end

post '/' do
	@name = params['name']

	result = db.execute (
		"SELECT id FROM users WHERE name = '#{@name}'"
	)
	puts @name
	puts result
	if result.length == 0
		puts "No ID"
		db.execute(
			"INSERT INTO users (name) VALUES(?)", @name
		)
		result = db.execute (
			"SELECT id FROM users WHERE name = '#{@name}'"
		)
	end
	puts result
	id = result.shift['id']
	db.execute(
		"INSERT INTO guestbook (name_id, message) 
		VALUES (?, ?)", id, params['message']
	)
	puts "Inserted into guestbook"
	erb File.read('thanks.erb')
end

post '/users/:username' do
	puts "#{params['username']} to #{params['name']}"
	@username = params['username']
	@name = params['name']
	result = db.execute (
		"SELECT id FROM users WHERE name = '#{@username}'"
	)
	puts result
	name_found = result.length
	if name_found != 0
		db.execute(
			"UPDATE users
			 	SET name = '#{@name}'
			 WHERE id = #{result.shift['id']}"
		)
	end
	erb File.read('changed_name.erb')
end
