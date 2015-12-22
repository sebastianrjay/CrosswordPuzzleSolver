# ABOUT

This app lets you write your own crossword puzzle and play it, or have the 
computer solve it for you at any time while playing.

# DIRECTIONS

Assuming you've [installed Ruby](https://github.com/rbenv/rbenv) and then installed
bundler via `gem install bundler`, navigate to the CrosswordPuzzleSolver root 
directory in the terminal and enter `bundle install`. To run the puzzle solver, 
enter `ruby lib/game.rb`. 

The goal here is to be able to look up a clue number and its text by 
position, and to be able to check which (if any) clue number to print in 
a certain puzzle position in O(1) time when running the game.

The challenge during puzzle instantiation is that we need to retrieve 
clues by position, and don't have their position when parsing the clues 
file. To save ourselves from building and storing another hash in 
O(m * n) time and O(clues) space, we redundantly store clue number and 
orientation in a deeper hash within @clues that we need to create 
anyway, so we can simply copy the deeper hash to a Word, which is stored 
under position in CrosswordPuzzle.
