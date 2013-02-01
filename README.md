So today we're going to learn a couple of basic techniques to make the data that we're storing from users more managable in the long run, and so that we'll be able to get more valuable information from our data.

Last week, we learned how to manipulate a relational database, but we didn't really go into what the term 'relational' means in terms of databases.  This week we're going to create a secondary table and reference them.

From our previous example, we had a single table, called "books", which stored a very limited amount of information.

	CREATE TABLE books (
		title VARCHAR(255),
		in_stock INT(11)
	);

Now, let's assume that we wanted to store data about not only the title of the book and how many we have in stock, but also the author.

The most straightforward way to accomplish that would be to add more fields to the books table.

	CREATE TABLE books (
		title VARCHAR(255),
		author VARCHAR(255),
		author_biography VARCHAR(255),
		in_stock INT(11)
	);

Now, there are a lot of problems with this approach in the real world.  Some clerks might input the author name as "Austen, Jane", and others as "Jane Austen".

And of course, clerks have been complaining that they have to type a new author biography every time a new book comes into the shop.  It's getting to be a huge time sink.

So the process of database design, figuring out how to organize your data into tables, has a lot to do with looking at the places where the data is repeated in more than one single, canonical record in the database.  Anywhere that happens, we might want to think about creating a new table to store that data in a single place.

To start off, let's create a second table, for authors.

	CREATE TABLE authors (
		first_name VARCHAR(255),
		last_name VARCHAR(255),
		biography VARCHAR(255)
	);

Now, we can add Jane Austen to the authors table and know we're talking about the right author.

	INSERT INTO authors VALUES ('Jane', 'Austen', 'Wrote a bunch of books.');

So now the data won't be duplicated, but how do we link it to the books table?  We can designate something called a primary key on the authors table, which means that this field is unique to each specific author.  We obviously can't do that right now, since many authors share first or last names with other authors.

We'd also be in trouble if authors ever change their names, or we realize we'd entered one incorrectly.

So what we can do is create a numeric field, perhaps called id.

	CREATE TABLE authors (
		id INTEGER PRIMARY KEY,
		first_name VARCHAR(255),
		last_name VARCHAR(255),
		biography VARCHAR(255)
	);

And so that we never have to worry about it ever again, we can set that field to auto increment, which means that a unique number will be placed into every new entry in the authors table.

	CREATE TABLE authors (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		first_name VARCHAR(255),
		last_name VARCHAR(255),
		biography VARCHAR(255)
	);

So now, in our book table, we can refer to the author of the book by referencing this ID, and we know we'll always be pointing to the correct author.

	CREATE TABLE books (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		title VARCHAR(255),
		author_id INT(11),
		price INT(11),
		in_stock INT(11)
	);

We're still storing the same author_id number for a bunch of different book records, but this is alright because we know that author_id will never change. Its only purpose is to act as a reference.

In this case, author_id in the books table is called a foreign key, since it refers to another table's primary key.  And the relationship that we've created is called a one-to-many, since one author is referenced by many books.

If we wanted to create a many-to-many relationship, meaning that multiple authors can be listed for a single book, we'd have to create a third table to store that relationship.  But we won't worry about that right now.

We need to get this data back out again.  It would be inconvenient to have to select the book with the title we want, note the author_id number, and do a second query on the authors table to get that information.

What we can do in SQL is called a JOIN operation.  This brings the data of several tables together by linking them along common fields, usually foreign keys linked with primary keys.

So let's say we wanted to get the titles of books along with the names of the authors:

	SELECT * FROM books 
	    JOIN authors ON books.author_id = authors.id;

You probably recognize most of the select statement already.  The only thing that's new is that we're telling the database that we'd like to also pull information from the author's table into relevant rows of the books table.

In this case, we're telling the database to pull data from the authors table into each book record when the author_id field on the books table matches the id field on the authors table.

We could also add a WHERE clause to this, and anything else we might be able to do with a normal SELECT statement.

	SELECT * FROM books 
	    JOIN authors ON books.author_id = authors.id
	    WHERE authors.first_name = "Jane";

Now, when we update the author biography for a given authors record, that data is automatically displayed whenever we query for books and join the authors table.  We can always be sure it's up-to-date.

A many-to-many relationship is a little bit harder, but not really that insurmountable.  Let's say that we want to keep track of genres for books.  Books can have more than one genre, and a genre can apply to more than one book.

We'd create a table called genres with a primary key.

	CREATE TABLE genres (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name VARCHAR(255)
	);

But we can't really link genres directly in the books table, since there's only one field to store the foreign key.  So we'd only be able to store one genre.  The same is true for the genres table.  We could link a book for each genre, but we'd only have one field per genre, and so we'd only be able to link one book to each.

What we need to do is create a linking table.

	CREATE TABLE books_genres (
		book_id INTEGER,
		genre_id INTEGER
	);

And we'd join the tables by doing a query that looks pretty much the same as the previous join statement, except that there's an extra one.

	SELECT books.title FROM books
		JOIN books_genres ON books_genres.book_id = books.id
		JOIN genres ON books_genres.genre_id = genres.id
	WHERE genres.name = "action";

Now that we've got our Creating and our Retrieving, let's move on to the update operation, the third initial in our CRUD acronymn.

An update statement looks like this:

	UPDATE books
		SET title = 'The Great Gatsby'
	WHERE id = 17;

It's basically the same syntax we've seen with everything else.  Just make sure you're careful with your WHERE clauses.  I used to interview software engineering candidates with code that looked something like this, and ask them what was wrong with it.

	db.exec "
		UPDATE books
			SET title = 'The Great Gatsby'
		WHERE #{id};
	"

If you're putting the id you're looking for into the where clause, but not specifying the field, the WHERE clause is always going to return true.  It's a very easy mistake to overlook--very few people could actually spot it in the interviews--but if you ran this code on production, every book in your store would end up being updated to have the title The Great Gatsby.

We're going to use what we've learned in this example to do a new version of the sites we created last week.  The repository for Lesson 04 starts out as simply a finished version of last week's lesson which I then broke again by adding bad table definitions to.  There are new tests in the tests.rb file, which give off really unhelpful errors about Integers when you first try to run the tests.

We want to have a concept of users in our system, so that we can make a GET request to /users/user_name and see all the posts made by the user with that name.  Users should also be able to change their names if they want to, without losing their post history.

To complete the assignment, you're going to have to create a second table in your database for users, and link the messages table to the users table in order to determine the current username.

One really useful thing Sinatra allows us to do is pass variable names through our path when we create a get or post handler. So, instead of making a new route for every single user name, we can write a method like this:

	get '/users/:name' 
		puts "User's name is #{params['name']}."
	end

The test runner is going to expect the following pages to exist:

* GET /users/ followed by a username to see all of that user's posts.  If that user doesn't exist, the message, `Sorry, the user "@name" doesn't exist.` is displayed instead.
* GET /users/ followed by a username and /edit to edit that user's name
* POST /users/ followed by a username to update a user based on form inputs (the test script is sending a form parameter called "name")

There's no login form or anything (we'll get to that later), so just create a new user in the database if you can't find one with the same name.

Remember to create a pull request once your tests have passed so I can get a rough idea of how everyone is doing on the assignment.