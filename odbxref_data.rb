
require_relative 'parse_bible_ref'

def each_archive
  Dir['archive/*.json'].group_by { |c| c[/\d+/] }.sort.each do |year, files|
    puts "Processing year #{year}... (#{files.length} files)"
    files.each do |file|
      yield JSON.parse(File.read(file))
    end
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
  text.sub! '(NIV)',            ''                                # 1995-01-08
  text.sub! 'Acts:',            'Acts'                            # 1995-02-13
  text.sub! 'Eccl.',            'Ecclesiastes'                    # 1998-05-11
  text.sub! 'Dt.',              'Deuteronomy'                     # 1998-10-17
  text.sub! '1 Th.',            '1 Thessalonians'                 # 1998-10-19
  text.sub! %r(\A-),            ''                                # 1999-06-06
  text.sub! 'Ps.',              'Psalm'                           # 1999-11-26
  text.sub! 'Mk.',              'Mark'                            # 1999-12-20
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
    max_date = [0,0,0]
    max_article = nil

    each_article do |article|
      passages = []
      books = []
      max_date = [max_date, article["date"]].max
      if article["date"] == max_date
        max_article = article
      end
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
        :book_name => BibleReference::BOOKS[i],
        :count => book_counter[book],
        :verses => BibleReference::VERSES[i],
        :chapters => BibleReference::VERSES[i].length
      }
    end

    split_book(index[:books], chapter_files, 'psa', [1, 42, 73, 90, 107, 151])

    chapter_files.each do |book, hash|
      filename = "chapters/#{book}.json"
      puts "==> #{filename}"
      File.write(filename, my_pretty_json(hash, 3, -1))
    end


    filename = "chapters/index.json"
    puts "==> #{filename}"
    index[:state] = "Articles from 1994-01-01 to #{'%04d-%02d-%02d' % max_date} (#{max_article["title"]}) have been indexed."
    File.write("commit.msg", %Q(Index up to #{'%04d-%02d-%02d' % max_date} "#{max_article["title"]}"))
    File.write(filename, my_pretty_json(index, 3, 0))

  end
end

def split_book(book_list, lookup_table, book_to_split, chapters)

  old_book_index = book_list.index { |book| book[:id] == book_to_split }
  old_book = book_list[old_book_index]
  old_articles = lookup_table[book_to_split]
  id = old_book[:id]

  # split the book into many chapters
  book_range = chapters.each_cons(2).map { |a, b| ((a - 1)..(b - 2)) }

  # move books from old index to new
  old_articles.each do |chapter_number, articles|
    new_id = "#{id}#{1 + book_range.index { |x| x.include? chapter_number - 1 }}"
    lookup_table[new_id][chapter_number] = articles
  end
  
  # create a listing of new books
  new_books = book_range.each_with_index.map { |range, index|
    number = index + 1
    new_id = "#{id}#{number}"
    count = lookup_table[new_id].values.flatten(1).uniq.length
    old_book.merge({
      :id => new_id,
      :name => "#{old_book[:name]} #{1 + range.first} – #{1 + range.last}",
      :verses => old_book[:verses][range],
      :index => old_book[:index] + (0.1 * (1 + index)),
      :count => count
    })
  }

  # replace and delete
  lookup_table.delete(book_to_split)
  book_list[old_book_index..old_book_index] = new_books
  
end




