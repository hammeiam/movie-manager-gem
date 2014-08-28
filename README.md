# MovieManagerGem

DH Movie Manager is a command line tool for organizing local movie files. 

DHMM finds local movie files, queies Rotten Tomatoes, and stores the data in a sqlite3 database that you can use to run commands. Search for specific actors, directors, and genres. Filter results by audience score. Update your filenames to reflect the correct title. 
Feeling indecisive? use the 'play unseen [genre]' command to play a random movie that suits your mood.

## Installation

Add this line to your application's Gemfile:

    gem 'movie_manager_gem'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install movie_manager_gem

## Usage

--- Below are a list of valid commands. Brackets [] indicate user input. ---

'start [file path]' drag and drop in the folder that holds your movies to add them to the database

'search actor [name] [rating (optional)]' 		returns a list of actors with the given name
'search director [name] [rating (optional)]' 	returns a list of directors with the given name
'search genre [genre] [rating (optional)]' 		returns a list of movies with the given genre
'search movies [rating]' 											returns a list of all movies with a RottenTomatoes Audience Score above [rating]

'play [title]' plays movie with the given title
'play unseen [genre] [rating (optional)]' plays random movie that you haven't seen from the given genre

'update watched' 			user will be asked which movies they have seen. This improves the 'play unseen [genre] function.
'update file names' 	user can choose to update movie file names with the correct titles

Examples:
search actor Stallone 60    (note that first or last names can be used. Min movie rating is optional)
play finding nemo 					(note that names and title searches can be more than 1 word long)
play unseen com 						(note that partial searches for names and genres are allowed. This will play a comedy)


## Contributing

1. Fork it ( https://github.com/hammeiam/movie_manager_gem/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
