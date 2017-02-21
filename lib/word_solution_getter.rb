module WordSolutionGetter

	SOLUTION_WEBSITE_NAMES = [
		CROSSWORD_GIANT = :crossword_giant,
		CROSSWORD_HEAVEN = :crossword_heaven
	]

	SOLUTION_SEARCH_URLS = {
		CROSSWORD_GIANT => 'http://www.crosswordgiant.com/search?clue=',
		CROSSWORD_HEAVEN => 'http://crosswordheaven.com/search/result?clue=&answer='
	}

	SOLUTION_TABLE_OFFSETS = {
		CROSSWORD_GIANT => 2,
		CROSSWORD_HEAVEN => 0
	}

	SOLUTION_TABLE_WIDTHS = {
		CROSSWORD_GIANT => 3,
		CROSSWORD_HEAVEN => 2
	}

	# Returns a match regex for the word's current letters, so that we can filter 
	# the word's clue's website search results against the letters we have so far
	def to_regex
		return Regexp.new("") if blank?

		# Building the regex takes O(word_length) time, so I always cache the result 
		# of this method in a variable when using it.
		x_start, y_start = @start_pos
		x_end, y_end = @end_pos
		regex_str = ""

		x_start.upto(x_end) do |x_i|
			y_start.upto(y_end) do |y_i|
				letter = @letter_positions[[x_i, y_i]]
				if letter
					regex_str += "[#{letter}]"
				else
					regex_str += "[A-Z]"
				end
			end
		end

		Regexp.new(regex_str)
	end

	def valid_solutions(website_name)
		regex = to_regex

		web_solutions(website_name).select {|word| word =~ regex }
	end

	private

		attr_accessor :crossword_giant_solutions, :crossword_heaven_solutions

		def web_solutions(website_name)
			# Cache them so we only request them over the internet once.
			# Use valid_solutions to narrow down solutions when we have more letters.
			solutions_cache_name = "#{website_name}_solutions"
			return self.send(solutions_cache_name) if self.send(solutions_cache_name)

			url = SOLUTION_SEARCH_URLS[website_name]
			offset = SOLUTION_TABLE_OFFSETS[website_name]
			width = SOLUTION_TABLE_WIDTHS[website_name]

			query_insertion_idx = url.index('=')
			search_url = url.dup.insert(query_insertion_idx + 1, query)
			response = RestClient.get(search_url).body
			regex = to_regex

			solutions = Nokogiri::HTML(response).css("td > a")
				.map(&:content).select.with_index do |str, idx| 
					# Checking the regex runs in O(string_length) time, so we do that last
					(idx + offset) % width == 0 && str.length == @length && str =~ regex
				end.uniq

			self.send("#{solutions_cache_name}=", solutions)
		end
end
