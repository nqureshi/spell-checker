# A ruby implementation of Peter Norvig's Bayesian spell-checker. 
# See here: http://norvig.com/spell-correct.html
# To use, clone the repo, load up Ruby, and then try:
# correct("somethin")       # => "something"
# correct("elenphant")      # => "elephant"

# Return all the words in a text, lowercased
def words(text)
  text.downcase.scan(/[a-z]+/)
end

# Create a model of the English language: a hash containing each word in the 
# text as the keys and a count of occurrences in the values
def train(features)
  # New words have keys initialized to 1; this is Python's defaultdict
  model = Hash.new { |hash, key| hash[key] = 1 }
  features.each { |word| model[word] += 1 }
  model
end

# Open the big.txt file and store the language model
NWORDS = train(words(File.open('big.txt','r').read))
ALPHABET = 'abcdefghijklmnopqrstuvwxyz'

# Return an array of anything one 'edit length' away from the word. An edit
# length means 1 letter either deleted (e.g. for ruby, 'rby'), transposed 
# (e.g. 'rbuy'), replaced (e.g. 'rlby'), or inserted (e.g. 'rluby')
def edits1(word)
  # Split the word into nested pairs of each permutation
  split = 0.upto(word.length).map { |i| [word[0...i], word[i..word.length-1]] }
  deletes = split.map { |a,b| a.to_s + b[1..b.length].to_s unless b.empty? }
  transposes = split.map { |a,b| a + b[1] + b[0] + b[2..b.length] if b.length > 1 }
  # Ugly code for replaces. I should be able to improve this.
  replaces = []
  ALPHABET.each_char do |letter|
    split.each do |a,b|
      replaces << a + letter + b[1..b.length] unless b.empty?
    end
  end
  # Ditto.
  inserts = []
  ALPHABET.each_char do |letter|
    split.each do |a,b|
      inserts << a + letter + b
    end
  end
  # Return an array of all the possibilities, unique and with 'nil' removed
  result = deletes + transposes + replaces + inserts
  result.uniq.compact
end

# Return an array of stuff 2 edit lengths away, by doing edit1 on its own 
# results
def known_edits2(word)
  result = []
  edits1(word).each { |e1| edits1(e1).each { |e2| result << e2 } }
  known(result)
end

# Eliminate non-words from any array. This code could be made more concise.
def known(words)
  if words.class == Array
    result = words.delete_if { |word| !NWORDS.has_key?(word) }.uniq
    return nil unless result.any?
    result
  else
    words if NWORDS.has_key?(words)
  end
end

# The main function: prioritizes the original word if it's correct, then words 
# an edit length away, then words 2 edit lengths away. Rather crude.
def correct(word)
  known(word) if known(word)
  candidates = known(edits1(word)) || known_edits2(word) || [word]
  ranking = candidates.map { |w| NWORDS[w] }.index(candidates.map { |w| NWORDS[w] }.max)
  candidates[ranking]
end
