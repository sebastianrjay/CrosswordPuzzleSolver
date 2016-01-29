module WordSolutionGetter

	# Returns a match regex for the word's current letters, so that we can filter 
	# the word's clue's database search results against the letters we have so far
	def to_regex
		return Regexp.new("") if blank?

		# Building the regex takes O(word_length) time, so I always cache the result 
		# of this method when using it.
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

	def valid_solutions(crossword_giant_solutions_are_insufficient)
		regex = to_regex

		if crossword_giant_solutions_are_insufficient
			crossword_heaven_solutions.select {|word| word =~ regex }
		else
			crossword_giant_solutions.select {|word| word =~ regex }
		end
	end

	private

		attr_accessor :cg_solutions, :ch_solutions

		def crossword_giant_solutions
			url = 'http://www.crosswordgiant.com/search?clue='
			web_solutions("cg_solutions", url, 2, 3)
		end

		def crossword_heaven_solutions
			url = 'http://crosswordheaven.com/search/result?clue=&answer='
			web_solutions("ch_solutions", url, 0, 2)
		end

		def web_solutions(solutions_cache_name, url, offset, modulo)
			# Cache them so we only request them over the internet once.
			# Use valid_solutions to narrow down solutions when we have more letters.
			return self.send(solutions_cache_name) if self.send(solutions_cache_name)

			query_insertion_idx = url.index('=')
			response = RestClient.get(url.insert(query_insertion_idx + 1, query)).body
			regex = to_regex

			solutions = Nokogiri::HTML(response).css("td > a")
				.map(&:content).select.with_index do |str, i| 
					# Checking the regex runs in O(string_length) time, so we do that last
					(i + offset) % modulo == 0 && str.length == @length && str =~ regex
				end.uniq

			self.send((solutions_cache_name + "="), solutions)
		end
end
