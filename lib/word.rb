require 'nokogiri'
require 'rest-client'

class Word
	attr_reader :clue, :length, :letter_positions, :letters_remaining, :query

	def initialize(options)
		@clue = options[:clue]
		@query = clue[:text].gsub(/(\d+\.|\d+\)|\d)/, '').strip.gsub(' ', '+')
		@start_pos, @end_pos = options[:start_pos], options[:end_pos]
		set_letter_positions
		@length = @letter_positions.length
		@letters_remaining, @cg_solutions, @ch_solutions = @length, nil, nil
	end

	def as_regex
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

	def blank?
		@letters_remaining == @length
	end

	def delete_letter(pos)
		if @letter_positions[pos]
			letter = @letter_positions[pos]
			@letter_positions[pos] = nil
			@letters_remaining += 1
			letter
		end
	end
	
	def get_letter(pos)
		@letter_positions[pos]
	end

	def inspect
		x_start, y_start = @start_pos
		x_end, y_end = @end_pos
		inspect_str = ""

		x_start.upto(x_end) do |x_i|
			y_start.upto(y_end) do |y_i|
				letter = @letter_positions[[x_i, y_i]]
				letter ? (inspect_str += letter) : (inspect_str += "_")
			end
		end

		inspect_str
	end

	def intersection_positions(puzzle)
		@intersection_positions ||= @letter_positions.keys.select do |pos|
			puzzle.word_positions[pos].length > 1
		end
	end

	def intersecting_words(puzzle)
		@intersecting_words ||= @letter_positions.map do |pos, letter|
			puzzle.word_positions[pos].find {|word| word != self }
		end
	end

	def set_as_string(string, puzzle)
		x_start, y_start = @start_pos
		x_end, y_end = @end_pos
		i = 0

		x_start.upto(x_end) do |x_i|
			y_start.upto(y_end) do |y_i|
				puzzle.set_letter([x_i, y_i], string[i])
				i += 1
			end
		end

		@letters_remaining = 0
	end

	def set_letter(pos, letter)
		if solved?
			puts "\nAre you sure you want to modify the solved word(s) at the 
position #{pos}? (y/n)"
	    input = gets.chomp
	    return unless input.downcase == "y"
	  end
		
		if @letter_positions[pos]
			@letter_positions[pos] = letter
		else
			@letters_remaining -= 1
			@letter_positions[pos] = letter
		end
	end

	def solved?
		@letters_remaining == 0
	end

	def valid_solutions(crossword_heaven_solutions_are_insufficient)
		regex = as_regex

		if crossword_heaven_solutions_are_insufficient
			crossword_giant_solutions.select {|word| word =~ regex }
		else
			crossword_heaven_solutions.select {|word| word =~ regex }
		end
	end

	private

		attr_accessor :cg_solutions, :ch_solutions

		def set_letter_positions
			x_start, y_start = @start_pos
			x_end, y_end = @end_pos
			@letter_positions = {}

			x_start.upto(x_end) do |x_i|
				y_start.upto(y_end) do |y_i|
					@letter_positions[[x_i, y_i]] = nil
				end
			end
		end

		def crossword_giant_solutions
			url = 'http://www.crosswordgiant.com/search?clue='
			web_solutions("cg_solutions", url, 2, 3)
		end

		def crossword_heaven_solutions
			url = 'http://www.crosswordheaven.com/search?clue=&answer='
			web_solutions("ch_solutions", url, 0, 2)
		end

		def web_solutions(cached_instance_var, url, offset, modulo)
			# Cache them so we only request them over the internet once.
			# Use valid_solutions to narrow down solutions when we have more letters.
			return self.send(cached_instance_var) if self.send(cached_instance_var)

			query_insertion_idx = url.index('=')
			response = RestClient.get(url.insert(query_insertion_idx + 1, query)).body
			regex = as_regex

			solutions = Nokogiri::HTML(response).css("td > a")
				.map(&:content).select.with_index do |str, i| 
					# Checking the regex runs in O(string_length) time, so we do that last
					(i + offset) % modulo == 0 && str.length == @length && str =~ regex
				end.uniq

			self.send((cached_instance_var + "="), solutions)
		end
end
