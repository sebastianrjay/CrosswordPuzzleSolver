require 'nokogiri'
require 'rest-client'
require_relative './word_solution_getter'

class Word
	include WordSolutionGetter

	attr_reader :clue, :length, :letter_positions, :letters_remaining, :query

	def initialize(options)
		@clue = options[:clue]
		@query = clue[:text].gsub(/(\d+\.|\d+\)|\d)/, '').strip.gsub(' ', '+')
		@start_pos, @end_pos = options[:start_pos], options[:end_pos]
		set_letter_positions!
		@length = @letter_positions.length
		@letters_remaining, @cg_solutions, @ch_solutions = @length, nil, nil
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

	def set_as_string(string, puzzle)
		x_start, y_start = @start_pos
		x_end, y_end = @end_pos
		i = 0

		x_start.upto(x_end) do |x_i|
			y_start.upto(y_end) do |y_i|
				puzzle.set_letter([x_i, y_i], string[i], true)
				i += 1
			end
		end

		@letters_remaining = 0
	end

	def set_letter(pos, letter)
		if solved?
			puts "\nAre you sure you want to modify the solved word #{self.inspect} at 
the position #{pos}? (y/n)"
	    input = gets.chomp
	    return unless input.downcase == "y"
	  end
		
		set_letter!(pos, letter)
	end

	def set_letter!(pos, letter)
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

	private

		def set_letter_positions!
			x_start, y_start = @start_pos
			x_end, y_end = @end_pos
			@letter_positions = {}

			x_start.upto(x_end) do |x_i|
				y_start.upto(y_end) do |y_i|
					@letter_positions[[x_i, y_i]] = nil
				end
			end
		end
end
