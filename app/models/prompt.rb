# Typing prompts for a round. Kept as plain ASCII sentences so the
# character-by-character comparison works reliably without an IME.
class Prompt
  SENTENCES = [
    "The quick brown fox jumps over the lazy dog.",
    "Pack my box with five dozen liquor jugs.",
    "Sphinx of black quartz, judge my vow.",
    "How vexingly quick daft zebras jump!",
    "The five boxing wizards jump quickly.",
    "Bright vixens jump; dozy fowl quack.",
    "We promptly judged antique ivory buckles for the next prize.",
    "A wizard's job is to vex chumps quickly in fog.",
    "Crazy Frederick bought many very exquisite opal jewels.",
    "Quick zephyrs blow, vexing daft Jim.",
    "Two driven jocks help fax my big quiz.",
    "Jinxed wizards pluck ivy from the big quilt.",
    "Speed and accuracy both matter when you type a sentence.",
    "Keep your fingers on the home row and stay calm.",
    "Practice every day and your words per minute will climb."
  ].freeze

  def self.random_text
    SENTENCES.sample
  end
end
