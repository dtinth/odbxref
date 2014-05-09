
require_relative 'parse_bible_ref'

def each_archive
  Dir['archive/*.json'].each do |file|
    yield JSON.parse(File.read(file))
  end
end

def each_article
  each_archive do |archive|
    archive["articles"].each do |article|
      yield article
    end
  end
end

command :chapters do |c|
  c.action do

    chapter_files = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = [ ] } }
    book_counter = Hash.new(0)

    each_article do |article|
      passages = []
      passage_ref = BibleReference.parse(article["passage"])
      article['passage_ref'] = passage_ref
      books = []
      passage_ref.each do |start, finish=nil|
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
    File.write(filename, my_pretty_json(index, 3, 0))

  end
end




