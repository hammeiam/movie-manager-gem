# MovieManagerGem

DH Movie Manager is a command line tool for organizing local movie files. 

DHMM finds local movie files, queies IMDB, and stores the data in a sqlite3 database that you can use to run commands. Search for specific actors, directors, and genres. Filter results by audience score. Update your filenames to reflect the correct title. 

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

If this is the first time using DHMM, you will be asked to tell the program where to find your movie files (trust me when I say you don't want the program looking through your entire harddrive). Using the 'start' command, drag and drop in the folder that holds your movies to add them to the database:

		start [file path]

See information about a particular movie:

		info [title]

Return a list of actors with the given name:

		search actor [name] [rating (optional)]	

Return a list of directors with the given name:

		search director [name] [rating (optional)]

Return a list of movies with the given genre:

		search genre [genre] [rating (optional)]	

Return a list of all movies with a RottenTomatoes Audience Score above [rating]:	

		search movies [rating]										


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

## New in Version 0.0.3
- Switched from Rotten Tomatoes to IMDB. This allows for accurate results from less precise file names.
- IMPORTANT! Changed database structure to include length, summary, and IMDB's ratings. This means we have to re-index your movies. 
- Added 'info' function to see all the relevant info about a given movie
- Updated /bin file to include this functionality
- Added versions to gem requirements, generally made code a little cleaner (removing empty methods, unnecessary comments)
- Improved feedback when unable to find movies of a given genre above a given rating

## Contributing

1. Fork it ( https://github.com/hammeiam/movie_manager_gem/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
