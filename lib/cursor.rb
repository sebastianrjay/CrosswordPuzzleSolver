class Cursor
  attr_accessor :position

  def initialize(puzzle_width, puzzle_height)
    @position = [0, 0]
    @puzzle_width, @puzzle_height = puzzle_width, puzzle_height
  end

  def move!(direction)
    case direction
    when "up"
      @position = position[0] - 1, position[1]
    when "down"
      @position = position[0] + 1, position[1]
    when "left"
      @position = position[0], position[1] - 1
    when "right"
      @position = position[0], position[1] + 1
    end

    force_in_bounds!
  end

  def force_in_bounds!
    position[0] = 0 if position[0] >= @puzzle_width
    position[0] = @puzzle_width - 1 if position[0] < 0

    position[1] = 0 if position[1] >= @puzzle_height
    position[1] = @puzzle_height - 1 if position[1] < 0

    position
  end
end
