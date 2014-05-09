
# This class parses the bible reference from raw text.
# For examples, please see the spec.
class BibleReference

  def self.parse(text)
    BibleReference.new(text).parse!
  end

  SHORT = [
    "gen", "exo", "lev", "num", "deu",
    "jos", "jdg", "rut", "1sa", "2sa", "1ki", "2ki", "1ch", "2ch", "ezr",
    "neh", "est", "job", "psa", "pro", "ecc", "sng", "isa", "jer", "lam",
    "ezk", "dan", "hos", "jol", "amo", "oba", "jon", "mic", "nam", "hab",
    "zep", "hag", "zec", "mal", "mat", "mrk", "luk", "jhn", "act", "rom",
    "1co", "2co", "gal", "eph", "php", "col", "1th", "2th", "1ti", "2ti",
    "tit", "phm", "heb", "jas", "1pe", "2pe", "1jn", "2jn", "3jn", "jud",
    "rev"
  ]

  BOOKS = [
    "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
    "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel", "1 Kings",
    "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra", "Nehemiah",
    "Esther", "Job", "Psalm", "Proverbs", "Ecclesiastes",
    "Song of Solomon", "Isaiah", "Jeremiah", "Lamentations",
    "Ezekiel", "Daniel", "Hosea", "Joel", "Amos", "Obadiah",
    "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai",
    "Zechariah", "Malachi",
    "Matthew", "Mark", "Luke", "John", "Acts", "Romans",
    "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians", "Philippians",
    "Colossians", "1 Thessalonians", "2 Thessalonians",
    "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews", "James",
    "1 Peter", "2 Peter", "1 John", "2 John", "3 John", "Jude", "Revelation"
  ]

  def initialize(text)
    text = text.strip
    text = text.gsub(/\s+/, ' ')
    text = text.gsub(/\u00a0/, ' ')  # Certain pages use non breaking space...
    text = text.sub(/\.$/, '')

    # hacks
    text = text.sub('1 Thessalonians.', '1 Thessalonians')

    @original = text
    @text = text
  end

  def parse!
    initialize_state
    until @text.empty?
      text_to_strip = parse_text
      @text = @text[text_to_strip.length..-1].strip
    end
    finalize_state
    @references
  rescue => e
    raise "#{e.message} : #{@original.inspect} #{@original.codepoints} -- fail at #{@text.inspect}"
  end

  private
  def parse_text
    BOOKS.each_with_index do |name, index|
      if @text.start_with?(name)
        bible_book(index)
        return name
      end
    end
    if @text =~ /\A\d+/
      match = $&
      number(match.to_i)
      return match
    end
    if @text =~ /\A:/
      match = $&
      colon
      return match
    end
    if @text =~ /\A[-–]/
      match = $&
      dash
      return match
    end
    if @text =~ /\A[;,]/
      match = $&
      separator
      return match
    end
    raise "Unable to parse!"
  end

  def initialize_state
    @references = []
    @current = []
    @book = nil
    @chapter = nil
    @verse = nil
    @has_verse = false
    @state = :book
  end

  def get_reference
    [@book, @chapter, @verse]
  end

  def bible_book(index)
    case @state
    when :book, :book_or_unspecified_number
      @book = SHORT[index]
      @has_verse = false
      @state = :chapter
    else
      raise "Unexpected book here!"
    end
  end

  def number(num)
    case @state
    when :chapter
      @chapter = num
      @state = :colon
    when :verse
      @verse = num
      @has_verse = true
      @state = :end
    when :unspecified_number, :book_or_unspecified_number
      @unspecified_number = num
      @state = :after_unspecified_number
    else
      raise "Unexpected number here!"
    end
  end

  def dash
    versify
    case @state
    when :end
      @state = :unspecified_number
      @current << get_reference
    else
      raise "Unexpected dash here!"
    end
  end

  def colon
    case @state
    when :colon
      @state = :verse
    when :after_unspecified_number
      @chapter = @unspecified_number
      @state = :verse
    else
      raise "Unexpected colon here!"
    end
  end
  
  def separator
    flush
  end

  def finalize_state
    flush
  end

  def versify
    case @state
    when :book_or_unspecified_number
      @state = :end
    when :after_unspecified_number
      if @has_verse
        @verse = @unspecified_number
      else
        @chapter = @unspecified_number
      end
      @state = :end
    when :colon
      @verse = nil
      @state = :end
    when :chapter
      @chapter = 1
      @verse = nil
      @state = :end
    end
  end

  def flush
    versify
    case @state
    when :end
      @current << get_reference
      @references << @current
      @current = []
      @state = :book_or_unspecified_number
    else
      raise "Unexpected $END here!"
    end
  end

end





