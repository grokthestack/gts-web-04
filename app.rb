require 'sinatra'
require "sqlite3"

database_file = settings.environment.to_s+".sqlite3"
db = SQLite3::Database.new database_file
db.results_as_hash = true
db.execute "
	CREATE TABLE IF NOT EXISTS guestbook (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
		user_id INT(11),
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
	@messages = db.execute "
          SELECT * FROM guestbook
            JOIN users ON guestbook.user_id = users.id";
	erb File.read('our_form.erb')
end

get '/users/:name' do
        @name = params['name']
        @user = db.execute "SELECT * FROM users WHERE name = '#{@name}'"
        unless @user.empty?
          @messages = db.execute "
            SELECT message FROM guestbook
              JOIN users ON guestbook.user_id = users.id
              WHERE users.name = '#{@name}'"
          erb File.read('profile.erb')
        else
          erb File.read('sorry.erb')
        end
end

get '/users/:name/edit' do
        @name = params['name']
        @user = db.execute "SELECT * FROM users WHERE name = '#{@name}'"
        unless @user.empty?
          erb File.read('change_name.erb')
        else
          erb File.read('sorry.erb')
        end
end

post '/users/:old_name' do
  @old_name = params['old_name']
  @user = db.execute "SELECT * FROM users WHERE name = '#{@old_name}'"
  unless @user.empty?
    @name = params['name']
    db.execute "INSERT INTO users(name) VALUES ('#{@name}')"
    db.execute "update guestbook
      set user_id = (select id from users where name = '#{@name}')
      where user_id = (select id from users where name = '#{@old_name}')"
    db.execute "DELETE from users where name = '#{@old_name}'" 
    @messages = db.execute "
      SELECT * FROM guestbook
        JOIN users ON guestbook.user_id = users.id";
    erb File.read('our_form.erb')
  else
    erb File.read('sorry.erb')
  end

end

post '/' do
	@name = params['name']
        @user = db.execute "SELECT * from users WHERE name = '#{@name}'"
        if @user.empty?
          db.execute "INSERT INTO users(name) VALUES ('#{@name}')"
          @user = db.execute "SELECT * from users WHERE name = '#{@name}'"
        end
        @message = params['message']
	db.execute "INSERT INTO guestbook(user_id, message) 
          VALUES ((SELECT id FROM users WHERE name = '#{@name}'), 
                  '#{@message}')"
	erb File.read('thanks.erb')
end
