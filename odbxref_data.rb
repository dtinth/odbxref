
require_relative 'parse_bible_ref'

def each_archive
  Dir['archive/*.json'].each do |file|
    yield JSON.parse(File.read(file))
  end
end

def each_article
  each_archive do |archive|
    archive["articles"].each do |article|
      preprocess_article(article)
      yield article
    end
  end
end

# Since ODB sometimes misspelt Bible names,
# we have to pre-process them first.
def preprocess_article(article)
  preprocess_reference(article, 'passage')
  preprocess_reference(article, 'quote')
end

def preprocess_reference(article, field)
  begin
    article[field] = fix_passage(article[field])
    ref = BibleReference.parse(article[field])
    article[field + "_ref"] = ref
  rescue => e
    puts "Unable to parse reference for #{article['date']}, #{article['url']}"
    raise e
  end
end

def fix_passage(text)
  text = text.strip
  text.sub! %r(\.$),            ''                                # 1994-10-07
  text.gsub! '+',               ' '                               # 2002-11-02
  text.sub! 'Rev.',             'Revelation'                      # 2005-03-31
  text.sub! 'Psalms',           'Psalm'                           # 2005-12-01
  text.sub! '7 Matthew',        '7; Matthew'                      # 2005-12-04
  text.sub! %r((2 John) (\d+)-(\d+)) do "#{$1} 1:#{$2}-#{$3}" end # 2007-06-19
  text.sub! 'Col.',             'Colossians'                      # 2009-09-29
  text.sub! '1 Thess.',         '1 Thessalonians'                 # 2010-03-05
  text.sub! '1 Cor.',           '1 Corinthians'                   # 2010-03-12
  text.sub! 'Phil.',            'Philippians'                     # 2010-03-26
  text.sub! '1 Tim.',           '1 Timothy'                       # 2010-04-18
  text.sub! '1 Chron.',         '1 Chronicles'                    # 2010-05-02
  text.sub! 'Heb.',             'Hebrews'                         # 2010-07-06
  text.sub! '2 Cor.',           '2 Corinthians'                   # 2010-07-10
  text.sub! %r(\A—),            ''                                # 2010-07-25
  text.sub! 'Gen.',             'Genesis'                         # 2010-08-21
  text.sub! 'Eph.',             'Ephesians'                       # 2010-09-08
  text.sub! 'Deut.',            'Deuteronomy'                     # 2011-01-30
  text.sub! '21 Matthew',       '21; Matthew'                     # 2011-05-17
  text.sub! 'Corthians',        'Corinthians'                     # 2011-12-08
  text.sub! %r(\u00A0),         ' '                               # 2012-08-05
  text.sub! 'Thessalonians.',   'Thessalonians'                   # 2012-08-06
  text
end


command :chapters do |c|
  c.action do

    chapter_files = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = [ ] } }
    book_counter = Hash.new(0)

    each_article do |article|
      passages = []
      books = []
      article["passage_ref"].each do |start, finish=nil|
        finish = start unless finish
        raise "Cross book!" if start[0] != finish[0]
        book = start[0]
        books << book
        chapters = (start[1]..finish[1])
        chapters.each do |chapter|
          passages << [book, chapter]
        end
      end
      passages.uniq.each do |book, chapter|
        chapter_files[book][chapter] << article
      end
      books.uniq.each do |book|
        book_counter[book] += 1
      end
    end

    index = { :books => [] }

    BibleReference::SHORT.each_with_index do |book, i|
      index[:books] << {
        :id => book,
        :index => i,
        :name => BibleReference::BOOKS[i],
        :count => book_counter[book],
        :verses => BibleReference::VERSES[i],
        :chapters => BibleReference::VERSES[i].length
      }
    end

    chapter_files.each do |book, hash|
      filename = "chapters/#{book}.json"
      puts "==> #{filename}"
      File.write(filename, my_pretty_json(hash, 3, -1))
    end

    filename = "chapters/index.json"
    puts "==> #{filename}"
    index[:state] = "Articles in 1994, 2002-2013, 2014 (Jan-Apr) have been indexed. 1995-2001 will be indexed by next month, hopefully."
    File.write(filename, my_pretty_json(index, 3, 0))

  end
end




