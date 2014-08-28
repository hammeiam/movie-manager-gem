require "movie-manager-gem/version"

module MovieManagerGem
  ### DH Searcher ###
	class Finder
		require 'rubygems'
		require 'rottentomatoes'
		require 'sequel'
		require 'thread'
		require 'sqlite3'	# sqlite3 implementation
		# require 'pg'	# postgres implementation

		include RottenTomatoes

		def initialize()
			# input Rotentomatoes api key
			Rotten.api_key = "9t2nx4s6bb62s8hvjftx8sx4"

			# start database
			@@DB = Sequel.sqlite('movies.db')	# sqlite3 implementation
			# @@DB = Sequel.postgres('testdb', :host=>'localhost', :user=>'David', :password=>'password')	# postgres implementation

			# create tables within database
			create_all_tables

			# tie ruby-accessible datasets to database table
			@movies_dataset						= @@DB[:movies]
			@movie_genre_dataset			= @@DB[:movie_genre]
			@genres_dataset						= @@DB[:genres]
			@directories_dataset			= @@DB[:directories]
			@movie_actor_dataset			= @@DB[:movie_actor]
			@actors_dataset						= @@DB[:actors]
			@movie_director_dataset		= @@DB[:movie_director]
			@directors_dataset				= @@DB[:directors]

			# joins
			@movie_directories_join 	= @movies_dataset.join(:directories, :id => :directory_id) # must be before other joins
			@movie_genre_join					= @movie_directories_join.join(:movie_genre, :movie_id => :movies__id).join(:genres, :id => :genre_id)
			@movie_actor_join					= @movie_directories_join.join(:movie_actor, :movie_id => :movies__id).join(:actors, :id => :actor_id)
			@movie_director_join			= @movie_directories_join.join(:movie_director, :movie_id => :movies__id).join(:directors, :id => :movie_director__director_id)

			# queues and threads
			@local_movies_queue				= Queue.new
			@processed_movies_queue		= Queue.new
			@threads									= []
		end

	### Update and Refine Data ###
		def initialized?
			@movies_dataset.first
		end

		def refine_unfound_movie_titles
				# for n in movies where original title == title
				# puts "What should the title of #{title} be?"
				# title = gets.chop 
		end

		def update_file_names
			# find where movie titles =0. 0=unchecked, 1=correct
			# for each, ask if title is correct
			# if yes, dataset.where(:id => each[:id]).update(:correct_filename => 1)
		  # else
		  incorrect_names = @movies_dataset.select(:id, :original_title, :title).where(:correct_filename => 0).all
		  incorrect_names.each do |name|
		  	puts "Is \"#{name[:title]}\" the correct title for \"#{File.basename(name[:original_title],".*")}\"? \n y/n"
		  	print '> '
		  	response = $stdin.gets.chomp.downcase
				#name[:id] == basename(name[:original_title],".*")
				case response
				when 'y','yes'
					new_title = File.dirname(name[:original_title]) + '/' + name[:title].gsub(/[\.|\_]/," ").gsub(/[\/|:]/,"-") + File.extname(name[:original_title])
					File.rename(name[:original_title], new_title) #this is also in normalize
					# mac replaces ':' with '/', this is a problem
					# directories get confused when a movie title has a '/' in it
					@movies_dataset.where(:id => name[:id]).update(:correct_filename => 1, :original_title => new_title)
					puts "File updated"
				when 'n', 'no'
					# incorrect title, must refine, replace our RT search records
					@movies_dataset.where(:id => name[:id]).update(:correct_filename => -1)
					puts "crap, sorry..."
				when 'end','exit'
					break
				else
					puts "Respond with 'y' or 'n'"
					# you'll have to run the command again to continue
				end
			end

			# http://sequel.jeremyevans.net/rdoc/files/doc/cheat_sheet_rdoc.html#label-Update%2FDelete+rows
			# be sure to bake in http://www.ruby-doc.org/core-2.1.2/File.html#method-c-rename
			#File.rename(old,new)
			#File.extname(file) gets extension
			#File.dirname(file)
			# change db record, change filename
		end

		def find_files_in(path) # works
			# should there be a default path? Path to this Dir.
			Dir.chdir(path) do
				enqueue_local_movies
				add_all_movies_to_table
				update_directories_status
			end
		end

		def update_watched_list # works
			@movies_dataset.where(:watched => -1).all.each do |movie|
				puts "Have you seen #{movie[:title]}? Y/N or end"
				print '> '
				response = $stdin.gets.chomp.downcase
				case response
				when 'y', 'yes'
					update_watched_status(movie[:title],1)
					puts 'Record updated'
				when 'n', 'no'
					update_watched_status(movie[:title],0)
					puts 'Record updated'
				when 'end'
					break
				else
					puts 'I didn\'t catch that..'
					update_watched_list
				end
			end
		end

	### List and Play Movies ###
		def list_all_movies(min_score=-1) # works
			movie_list = @movie_director_join.where({:available => 1}, (Sequel.expr(:audience_score) >= min_score)).group(:movies__id).order(:title).all # sqlite3 impementation
			# movie_list = @movie_directories_join.order(:title).distinct(:movies__id,:title).where({:available => 1}, (Sequel.expr(:audience_score) >= min_score)).all? # postgres implementation

			if movie_list.empty?
				puts "Sorry, we don\'t have any movies with a score higher than #{min_score}"
			else
				puts "--- Movies Rated Higher Than #{min_score} ---"
				movie_list.each{ |movie| puts movie[:title]} 
			end
		end

		def list_movies_with_director(director, min_score = -1) # works
			results_list = @directors_dataset.where(Sequel.ilike(:name, '%'+director+'%')).all
			if results_list.length > 1
				temp = []
				results_list.each {|result| temp << result[:name]}
				puts "Here are the results for '#{director}'. Please enter the number of the one you want."
				temp.each_with_index do |name,i| 
					puts "#{i+1}: #{name}"
				end
				print '> '
				director_name = temp[$stdin.gets.chomp.to_i - 1]

			elsif results_list.length == 1
				director_name = results_list[0][:name]

			else
				puts "Sorry, we couldn't find a director named '#{director}'. Here are the directors we have:"
				@directors_dataset.select(:name).order(:name).all.each {|director| puts '- ' + director[:name]}
				return
			end
			movie_list = @movie_director_join.where({:name => director_name}, {:available => 1},  (Sequel.expr(:audience_score) >= min_score)).group(:movies__id).order(:title).all  # sqlite3 implementation
			#movie_list = @movie_director_join.order(:title).distinct(:movies__id,:title).where({:name => director_name} & {:available => 1} & (Sequel.expr(:audience_score) >= min_score)).all  # postgres implementation

			if movie_list.empty?
				puts "Sorry, we don\'t have any movies directed by \'#{director_name}\'."
			else
				puts "--- Movies directed by '#{director_name}' ---"
				movie_list.each{ |movie| puts movie[:title]} 	
			end
		end

		def list_movies_with_actor(actor, min_score = -1) # works
			results_list = @actors_dataset.where(Sequel.ilike(:name, '%'+actor+'%')).all

			if results_list.length > 1
				temp = []
				results_list.each {|result| temp << result[:name]}
				puts "Here are the results for '#{actor}'. Please enter the number of the one you want."
				temp.each_with_index do |name,i| 
					puts "#{i+1}: #{name}"
				end
				print '> '
				actor_name = temp[$stdin.gets.chomp.to_i - 1]

			elsif results_list.length == 1
				actor_name = results_list[0][:name]

			else
				puts "Sorry, we couldn't find an actor named '#{actor}'. Here are the actors we have:"
				@actors_dataset.select(:name).order(:name).all.each {|actor| puts '- ' + actor[:name]}
				return
			end
			movie_list = @movie_actor_join.where({:name => actor_name}, {:available => 1}, (Sequel.expr(:audience_score) >= min_score)).group(:movies__id).order(:title).all  # sqlite3 implementation
			# movie_list = @movie_actor_join.order(:title).distinct(:movies__id,:title).where({:name => actor_name}, {:available => 1}, (Sequel.expr(:audience_score) >= min_score)).all  # postgres implementation

			if movie_list.empty?
				puts "Sorry, we don\'t have any movies starring \'#{actor_name}\'."
			else
				puts "--- Movies starring '#{actor_name}' ---"
				movie_list.each{ |movie| puts movie[:title]} 	
			end
		end

		def list_movies_by_genre(genre, min_score = -1) # works
			movie_list = @movie_genre_join.where(Sequel.ilike(:genre, '%'+genre+'%') & {:available => 1} & (Sequel.expr(:audience_score) >= min_score)).group(:movies__id).order(:title).all  # sqlite3 implementation
			# movie_list = @movie_genre_join.order(:title).distinct(:movies__id,:title).where(Sequel.ilike(:genre, '%'+genre+'%') & {:available => 1} & (Sequel.expr(:audience_score) >= min_score)).all # postgres implementation

			if movie_list.empty?
				puts 'Sorry, we don\'t have that genre. Please enter one from the list:'
				@genres_dataset.select(:genre).order(:genre).all.each {|genre| puts '- ' + genre[:genre]}
			else
				search_genre = movie_list.first[:genre]
				puts "--- Movies with genre '#{search_genre}' ---"
				movie_list.each{ |movie| puts movie[:title]} 
			end
		end

		def play_unseen_genre(genre, min_score = -1) # works
			movie_genre_list = @movie_genre_join.where(Sequel.ilike(:genre, '%'+genre+'%') & {:available => 1} & (Sequel.expr(:audience_score) >= min_score)).group(:movies__id).all  # sqlite3 implementation
			# movie_genre_list = @movie_genre_join.order(:title).distinct(:movies__id,:title).where(Sequel.ilike(:genre, '%'+genre+'%') & {:available => 1} & (Sequel.expr(:audience_score) >= min_score)).all  # postgres implementation
			if movie_genre_list.empty?
				puts "Sorry, we don\'t have any movies with the genre #{genre}."
				# this exception doesn't reveal if there are no movies of that genre above the minimum score
			else
				unwatched_list = movie_genre_list.select{|movie| movie[:watched] != 1}
				if unwatched_list.empty?
					puts "Sorry, you\'ve seen all of your #{genre} movies"
				else
					movie_title = unwatched_list.sample[:title]
					play(movie_title,false)
				end
			end		
		end

		def play(movie_title, user_input=true) # works
			# does a search for the title if a user input it. opens the exact file if another function provided the name
			if user_input
				movie_to_play = @movie_directories_join.where(Sequel.ilike(:title, '%'+movie_title+'%'), :available => 1).group(:movies__id).first  # sqlite3 implementation
				# movie_to_play = @movie_directories_join.order(:title).distinct(:movies__id,:title).where(Sequel.ilike(:title, '%'+movie_title+'%'), :available => 1).first  # postgres implementation
			else
				movie_to_play = @movies_dataset.where(:title => movie_title).first
			end

			if movie_to_play 
				puts "Play #{movie_to_play[:title]}? Y/N"
				print '> '
				response = $stdin.gets.chomp.downcase
				case response
				when 'y', 'yes'
					update_watched_status(movie_to_play[:title],1)
					system("open \"#{movie_to_play[:original_title]}\"")	# unix needs double quotes around file names with spaces
				when 'n', 'no'
					puts 'Okay...'
				else
					puts 'Speak English, man!'
					play(movie_title)
				end
			else
				puts "No movie named '#{movie_title}' found, try a different search"
			end
		end

	### Movie-handling fuctions ###

		def enqueue_local_movies 	# works
			movies_glob = Dir.glob('**/*.{mkv,MKV,avi,AVI,mp4,MP4,mpg,MPG,mov,MOV}').uniq
			movies_glob.each {|movie| @local_movies_queue << [File.absolute_path(movie), normalize_title(movie), nil]}
			#movies.select!{|movie| File.size(movie) > 600_000_000} # works
		end

		def normalize_title(title) # works
			# output should seperate path, suffix. Change periods and underscores to spaces. Possibly change / to : 
			File.basename(title,'.*').gsub(/[\.|\_]/," ").gsub(/[\/|:]/,"-")
		end

		def update_directories_status # works 
			@directories_dataset.select(:directory_path).all.each do |dir|
				if Dir.exists?(dir[:directory_path])
					@directories_dataset.where(:directory_path => dir[:directory_path]).update(:available => 1)
				else
					@directories_dataset.where(:directory_path => dir[:directory_path]).update(:available => 0)
				end
			end
		end

		def update_watched_status(movie_title, status)	# works. 
			@movies_dataset.where(:title => movie_title).update(:watched => status)
		end

		def add_all_movies_to_table	# works # add func to auto-find/add new movies. may need to rework enqueue_local_movies to output array
			# RottenTomatoes' API seems to error at >3 threads
			2.times do
				# this code was supplied by Theo on SO
				# http://stackoverflow.com/questions/6558828/thread-and-queue
				@threads << Thread.new do
					until @local_movies_queue.empty?
						long_name, clean_name, data = @local_movies_queue.pop(true) rescue nil
						if long_name
							if movies_record_exists?(long_name)
								movie_title = @movies_dataset.select(:title).where(:original_title => long_name).first[:title]
								puts "#{movie_title} record already exists"
							else
								data = get_rt_movie_info(clean_name)
								@processed_movies_queue << [long_name, clean_name, data]
								add_movie(@processed_movies_queue.pop)
							end
						end
					end
				end
			end
			@threads.each { |t| t.join } 
		end

		def add_movie((long_name, clean_name, data)) # works
			if data

				# Add Directories to directories_dataset
				@directories_dataset.insert(:directory_path =>  File.dirname(long_name)) unless directories_record_exists?(File.dirname(long_name))

				# Add Movie to movies_dataset
				@movies_dataset.insert( :original_title => long_name, 
					:title => data.title,
					:critic_score => data.ratings.critics_score,
					:audience_score => data.ratings.audience_score,
					:date_added => Time.new(),
					:directory_id => @directories_dataset.select(:id).where(:directory_path => File.dirname(long_name)).first[:id])

				movie_id = @movies_dataset.select(:id).where(:title => data.title).first[:id]

				# Add Actors to actors_dataset and movie_actor_dataset
				data.abridged_cast.each do |actor| 
					@actors_dataset.insert(:name => actor[:name]) unless actors_record_exists?(actor[:name]) # used to be :name => actor.name. Make sure this works online!
					@movie_actor_dataset.insert(:movie_id => movie_id,
						:actor_id => @actors_dataset.select(:id).where(:name => actor[:name]).first[:id])
				end if data.abridged_cast

				# Add Genres to genres_dataset and movie_genre_dataset
				data.genres.each do |genre| 
					@genres_dataset.insert(:genre => genre) unless genres_record_exists?(genre)
					@movie_genre_dataset.insert(:movie_id => movie_id,
						:genre_id => @genres_dataset.select(:id).where(:genre => genre).first[:id])
				end if data.genres

				# Add Directors to directors_dataset and movie_director_dataset 
				data.abridged_directors.each do |director|   
					@directors_dataset.insert(:name => director[:name]) unless directors_record_exists?(director[:name])
					@movie_director_dataset.insert(:movie_id => movie_id,
						:director_id => @directors_dataset.select(:id).where(:name => director[:name]).first[:id])
				end if data.abridged_directors

				puts "#{data.title} added to table" 

			else
				@movies_dataset.insert(:original_title => long_name, :title => clean_name, :date_added => Time.new())
				puts "#{clean_name} added to table"
			end
		end

		def get_rt_movie_info(clean_name) # works
			# with internet
			begin
				output = RottenMovie.find(:title => clean_name, :expand_results => true, :limit => 1)	# hits RT once to get general movie info
				sleep 1
				output = RottenMovie.find(:id => output.id)	if output.class == PatchedOpenStruct # hits RT a second time with id# to get most detailed info :(
			rescue		# addresses the occasional crash that RT limits plus our volume of calls can bring on.
				sleep 1
				output = RottenMovie.find(:title => clean_name, :expand_results => true, :limit => 1)	# hits RT once to get general movie info
				sleep 1
				output = RottenMovie.find(:id => output.id)	if output.class == PatchedOpenStruct # hits RT a second time with id# to get most detailed info :(
			end			
			return output if output.class == PatchedOpenStruct
			return nil

			# without internet (local offline testing)
			# output = FakeMovie.new(clean_name)
			# return output
		end


	### Exists? ###
	def movies_record_exists?(original)	
		return false if @movies_dataset.select(:id).where(:original_title => original).all.length == 0 
		return true
	end

	def actors_record_exists?(name)	
		return false if @actors_dataset.select(:id).where(:name => name).all.length == 0 
		return true
	end

	def directors_record_exists?(name)	
		return false if @directors_dataset.select(:id).where(:name => name).all.length == 0 
		return true
	end

	def genres_record_exists?(genre)
		return false if @genres_dataset.select(:id).where(:genre => genre).all.length == 0 
		return true
	end

	def directories_record_exists?(path)
		return false if @directories_dataset.select(:directory_path).where(:directory_path => path).all.length == 0 
		return true
	end

	### Tables & DBs ###
	def create_all_tables
		create_directories_table 	unless @@DB.table_exists?(:directories)

		create_movies_table 		unless @@DB.table_exists?(:movies)

		create_genres_table 		unless @@DB.table_exists?(:genres)
		create_movie_genre_table 	unless @@DB.table_exists?(:movie_genre)

		create_actors_table 		unless @@DB.table_exists?(:actors)
		create_movie_actor_table 	unless @@DB.table_exists?(:movie_actor)

		create_directors_table 		unless @@DB.table_exists?(:directors)
		create_movie_director_table unless @@DB.table_exists?(:movie_director)
	end

	def create_movies_table
		if @@DB.table_exists?(:movies)
			raise StandardError, 'Movies table already exists, try a different name'	
		else
			@@DB.create_table :movies do
				primary_key :id
				String  	:original_title
				String  	:title
				  Integer	:critic_score, 		:default => -1 	#1-100
				  Integer	:audience_score, 	:default => -1 	#1-100
				  Integer 	:my_score, 			:default => -1 	#1-100
				  Integer 	:correct_filename, 	:default => 0  	#0/no, 1/yes
				  Integer 	:watched, 			:default => -1 	#-1/unknown, 0/no, 1/yes
				  String  	:date_added
				  Integer 	:directory_id 
				end 
			end
		end

		def create_directories_table
			if @@DB.table_exists?(:directories)
				raise StandardError, 'Directories table already exists, try a different name'	
			else
				@@DB.create_table :directories do
					primary_key :id
					String :directory_path
					Integer :available, 		:default => 1
				end 
			end
		end

		def create_genres_table
			if @@DB.table_exists?(:genres)
				raise StandardError, 'Genres table already exists, try a different name'	
			else
				@@DB.create_table :genres do
					primary_key :id
					String :genre
				end
			end
		end

		def create_movie_genre_table
			if @@DB.table_exists?(:movie_genre)
				raise StandardError, 'Movie_Genre table already exists, try a different name'	
			else
				@@DB.create_table :movie_genre do
					primary_key :id
					Integer :movie_id
					Integer :genre_id
				end
			end
		end

		def create_actors_table
			if @@DB.table_exists?(:actors)
				raise StandardError, 'Actors table already exists, try a different name'	
			else
				@@DB.create_table :actors do
					primary_key :id
					String :name
				end
			end
		end

		def create_movie_actor_table
			if @@DB.table_exists?(:movie_actor)
				raise StandardError, 'Movie_Actor table already exists, try a different name'	
			else
				@@DB.create_table :movie_actor do
					primary_key :id
					Integer :movie_id
					Integer :actor_id
				end
			end
		end

		def create_directors_table 
			if @@DB.table_exists?(:directors)
				raise StandardError, 'Directors table already exists, try a different name'	
			else
				@@DB.create_table :directors do
					primary_key :id
					String :name
				end
			end
		end

		def create_movie_director_table
			if @@DB.table_exists?(:movie_director)
				raise StandardError, 'Movie_Director table already exists, try a different name'	
			else
				@@DB.create_table :movie_director do
					primary_key :id
					Integer :movie_id
					Integer :director_id
				end
			end
		end

		def drop_table(table_name = table_name.to_sym)
			if @@DB.table_exists?(table_name)
				puts "Are you sure you want to drop table \'#{table_name}\'? Y/N"
				response = 1000.chomp.downcase

				case response
				when 'y', 'yes'
					@@DB.drop_table(table_name)
					puts 'Table dropped'
				when 'n', 'no'
					puts 'Table not dropped'
				else
					puts 'Reply with Y or N'
					drop_table(table_name)
				end
			else
				raise StandardError, 'Table doesn\'t exist'
			end
		end
	end

	class FakeMovie 	# works
		# returns results when testing offline
		attr_reader :title, :ratings, :critics_score, :audience_score, :my_score, :genres, :abridged_directors, :abridged_cast, :correct_filename, :watched, :name
		def initialize(movie_title)
			sleep 2 # you have to wait for RT, you have to wait for me!

			@random							= Random.new
			@title 							= movie_title.upcase
			@my_score 					= @random.rand(100)+1
			@genres 						= %w(Comedy Documentary Drama Horror Western XXX).sample(@random.rand(3)+1)
			@correct_filename 	= @random.rand(2)
			@watched 						= @random.rand(2)

			# cast & director names
			@first 							= %w(Abe Bob Carl Dolf Earl)
			@last 							= %w(Buler Crabtree Daniels McDonald)

			# ratings
			@critics_score 			= 101
			@audience_score 		= 101
		end

		def ratings
			return self
		end

		def abridged_cast
			out = []
			(@random.rand(5)+1).times do
				out << {name: @first.sample + ' ' + @last.sample }
			end
			return out
		end

		def abridged_directors
			out = []
			(@random.rand(3)+1).times do
				out << {name: 'Director ' + @last.sample }
			end
			return out
		end
	end

#### TO DO: ####
#
# some directories are listed as NULL. Find out why and fix it.
#
# X add directories DB
# X - add "directory present?" column to movies DB 0/1
# X - add "directory_present?" function to update dir status, runs on initialization. We assume no devices are being removed within a session.
# X - add "directory_present => 1" to all existing searches
#
# X update add_all_movies_to_table. Auto-find/add new movies. 
#
# X if RT call fails, restart and continue. 
#
# X add ARGV for command line input, woo! Look into Thor to help list commands
#
# X Let user specify directory root. use Dir.chdir(new_dir). Volume can be dragged and dropped in. request on init.
#
# X func search by actor/director 
# X improve act/dir search with last name refinement
#
# Look into using Find instead of Dir.glob to allow the user to exclude some folders. 
# http://ruby-doc.org/stdlib-1.9.3/libdoc/find/rdoc/Find.html
# can maybe also use reject on glob
# http://stackoverflow.com/questions/4505566/is-there-a-way-to-glob-a-directory-in-ruby-but-exclude-certain-directories
#
# X func is x the correct name? y/n
#
# swtich back to sqlite3 to make this a one click startup.
#
# X create a setup command. if db is empty, spcify a dir to look in, add movies, update dirs. 
#
# X consider filtering actor/dir results if dir is unattached
# consider tracking play count rather than having it be binary
# consider making better use of the directory & origial movie name combo. feels redundant. 
#
# X func update file names to reflect correct titles. Will need to be unix-safe
# http://superuser.com/questions/358855/what-characters-are-safe-in-cross-platform-file-names-for-linux-windows-and-os
# 
# put on the web.
# Add filetypes. 
# How to deal with file being renamed by user?
# Look at 'index on expressions'
end
