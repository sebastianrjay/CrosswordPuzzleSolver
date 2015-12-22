module CrosswordFileParser

	def parse_clues_file(clues_filename)
		@clues, setting_across, setting_down = {}, false, false
		@clues[:across], @clues[:down] = {}, {}

		File.open(clues_filename).readlines.each do |raw_line|
			next if raw_line == "\n"
			
			line = raw_line.strip

			if line =~ /.?[Aa][Cc][Rr][Oo][Ss][Ss].?/
				setting_across, setting_down = true, false
				next
			elsif line =~ /.?[Dd][Oo][Ww][Nn].?/
				setting_across, setting_down = false, true
				next
			end

			clue = line.strip
			number = line.scan(/(\d|[A-Z])/).flatten.first

			if setting_across
				@clues[:across][number] = {}
				@clues[:across][number][:text] = clue
			elsif setting_down
				@clues[:down][number] = {}
				@clues[:down][number][:text] = clue
			end
		end
	end

	def parse_layout_file(layout_filename)
		begin
			horizontal_lines = File.open(layout_filename)
				.readlines.map(&:strip).select {|l| l != ""}
			vertical_lines = horizontal_lines.map(&:chars).transpose.map(&:join)

			@height = horizontal_lines.length
			@width = vertical_lines.length

		rescue => e
			msg = "\nYour layout file is formatted incorrectly. All rows in the 
layout file must be the same length. Please exit the game, fix the layout file 
and restart the game.\n"

			puts msg
		end

		save_word_positions(:across, horizontal_lines)
		save_word_positions(:down, vertical_lines)
	end

	def save_clue_and_blank_word(orientation, word_number, positions)
		@clues[orientation][word_number][:position] = positions.first
		@clues[orientation][word_number][:number] = word_number
		@clues[orientation][word_number][:orientation] = orientation

		word = Word.new({ start_pos: positions.first, 
			end_pos: positions.last, clue: @clues[orientation][word_number] })

		positions.each do |pos|
			@word_positions[pos] ||= []
			@word_positions[pos] << word
		end

		# O(1) time; @words is a Set
		@words << word unless @words.include?(word)
		@words_remaining += 1
	end

	def save_word_positions(orientation, lines)
		lines.each_with_index do |line, i|
			word_number, positions = nil, []
			line.chars.each_with_index do |char, j|
				current_position = (orientation == :down ? [j, i] : [i, j])

				# Words must be at least 2 squares long
				if char == "#" && word_number && positions.length > 1
					save_clue_and_blank_word(orientation, word_number, positions)
					word_number, positions = nil, []
				elsif char == "#"
					word_number, positions = nil, []
				elsif word_number
					positions << current_position
				elsif !word_number && char != "."
					word_number = char
					positions << current_position	
				end
			end

			# If it's the end of the row and we haven't hit a black square, then we 
			# need to save the current word before starting the next row.
			if word_number && positions.length > 1
				save_clue_and_blank_word(orientation, word_number, positions)
			end
		end
	end
end
