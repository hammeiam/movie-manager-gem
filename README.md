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

## Getting Started

From your home directory, simply run:

		movie-manager-gem 

## Usage
Below are a list of valid commands. Brackets indicate user input (don't use brackets when inputing arguments).

To begin, drag and drop in the folder that holds your movies to add them to the database:

		start [file path]

Return a list of actors with the given name:

		search actor [name] [rating (optional)]	

Return a list of directors with the given name:

		search director [name] [rating (optional)]

Return a list of movies with the given genre:

		search genre [genre] [rating (optional)]	

Return a list of all movies with a RottenTomatoes Audience Score above [rating]:	

		search movies [rating]' 											


Play a movie with the given title:

		play [title]

Play a random movie that you haven't seen from the given genre:

		play unseen [genre] [rating (optional)]


User will be asked which movies they have seen. This improves the 'play unseen [genre] function:

		update watched			

User can choose to update movie file names with the correct titles:

		update file names 	


Tips:
- Rating is an optional argument
- Partial searches (eg com vs comedy) can be used
- Searches can be multiple words (eg 'search actor Gary Oldman 60')

## Contributing

1. Fork it ( https://github.com/hammeiam/movie_manager_gem/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
