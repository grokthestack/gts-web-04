require 'sinatra'
require "sqlite3"

database_file = settings.environment.to_s+".sqlite3"
db = SQLite3::Database.new database_file
db.results_as_hash = true
db.execute "
	CREATE TABLE IF NOT EXISTS guestbook (
		message VARCHAR(255),
      user_id INT
	);
";

db.execute "
	CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
		name VARCHAR(255)
	);
";

get '/' do
	@messages = db.execute("SELECT name, message FROM guestbook JOIN users on user_id = id")
	erb File.read('our_form.erb')
end

get '/users/:name' do
   @user = params['name']
   if db.execute("SELECT count(*) from users where name = ?", @user)[0][0] > 0
      @posts = db.execute("SELECT message FROM guestbook JOIN users on user_id = id where name = ?", @user)
      erb File.read('user.erb')
   else
      @err = "Sorry, the user \"#{@user}\" doesn't exist."
      erb File.read('error.erb')
   end
end

post '/' do
	@name = params['name']
   query = db.execute("SELECT count(*) from users where name = ?", @name)
   @count = query[0][0]
   if @count <= 0
      db.execute("INSERT INTO users ( name ) VALUES( ? )", @name)
   end
   id = db.execute("SELECT id from users where name = ?", @name)[0]['id']
	db.execute(
		"INSERT INTO guestbook ( user_id, message ) VALUES( ?, ? )",
		id, params['message']
	);
	erb File.read('thanks.erb')
end

get '/users/:name/edit' do
   @name = params['name']
   if db.execute("SELECT count(*) from users where name = ?", @user)[0][0] > 0
      erb File.read('edit.erb')
   else
      @err = "Sorry, the user \"#{@name}\" doesn't exist."
      erb File.read('error.erb')
   end
end

post '/users/:old_name' do
   db.execute("UPDATE users set name = ? where name = ?",
         params['name'], params['old_name'])
   #puts "User #{params['old_name']} has been renamed to #{params['name']}"
end
