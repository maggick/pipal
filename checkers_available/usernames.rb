register_checker("Username_Checker")

begin
	require "levenshtein"
rescue LoadError
	# catch error and prodive feedback on installing gem
	puts "\nError: levenshtein gem not installed\n"
	puts "\t use: \"gem install levenshtein-ffi\" to install the required gem\n\n"
	exit
end

class Username_Checker < Checker

	def initialize
		super
		@exact_matches_name = []
		@lev_matches_name = []
		@lev_total_name = 0
		@lev_tolerance = 3

		@description = "Compare usernames to passwords."
		@cli_params = [['--username.lev_tolerance', GetoptLong::REQUIRED_ARGUMENT]]
	end

	def parse_params opts
		opts.each do |opt, arg|
			case opt
				when '--username.lev_tolerance'
				if arg =~ /^[0-9]*$/
					@lev_tolerance = arg.to_i
					if @lev_tolerance <= 0
						puts"\nUsername Checker: Please enter a positive distance\n\n"
						exit 1
					end
				else
					puts"\nUsername Checker: Invalid Levenshtein tolerance\n\n"
					exit 1
				end
			end
		end
	end

	def check_it (password, value)
		puts "Checking #{value} against #{password}" if @verbose
		if password == value
			puts "Exact match" if @verbose
			return {"distance" => 0, "value" => value, "password" => password}
		else
			dist = Levenshtein.distance(password, value)
			puts "Lev distance #{dist}#" if @verbose
			return {"distance" => dist, "value" => value, "password" => password}
		end

		return nil
	end

	def process_word (password, extras)
		if extras.has_key?("username")
			username = extras['username']

			res = check_it(password, username)
			unless res.nil?
				if res['distance'] == 0
					unless @exact_matches_name.include? username
						@exact_matches_name << {"name" => username}
					end
				else
					@lev_total_name += res["distance"]
					if res["distance"] <= @lev_tolerance
						@lev_matches_name << res
					end
				end
			end
		end

		@total_words_processed += 1
	end

	def get_results()
		ret_str = "Username Checker\n"
		ret_str << "================\n\n"

		ret_str << "Exact Matches\n"
		ret_str << "-------------\n"
		if @exact_matches_name.count > 0
			ret_str << "Total: #{@exact_matches_name.count.to_s}\n\n"

			@exact_matches_name.sort{|a,b| (a['name'] <=> b['name'])}.each do |match|
				ret_str << "#{match['name']} #{match['email']}\n"
			end
		else
			ret_str << "No Exact Matches\n"
		end

		ret_str << "\nLevenshtein Results\n"
		ret_str << "-------------------\n"
		lev_average = (@lev_total_name.to_f / @total_words_processed).round(2)
		ret_str << "Average distance (name) #{lev_average}\n"

		ret_str << "\nClose Matches\n"
		ret_str << "-------------\n"

		# Need to sort this then have it obey the cap_at value
		if @lev_matches_name.count > 0
			ret_str << "Total: #{@lev_matches_name.count.to_s}\n\n"
			@lev_matches_name.sort{|a,b| (a['distance'] <=> b['distance'])}[0, @cap_at].each do |user_pass|
				ret_str << "D: #{user_pass['distance']} U: #{user_pass['value']} P: #{user_pass['password']}\n"
			end
		else
			ret_str << "No matches within supplied tolerance\n"
		end

		return ret_str
	end
end