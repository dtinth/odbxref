
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

    each_article do |article|
      passages = []
      passage_ref = BibleReference.parse(article["passage"])
      article['passage_ref'] = passage_ref
      passage_ref.each do |start, finish=nil|
        finish = start unless finish
        raise "Cross book!" if start[0] != finish[0]
        book = start[0]
        chapters = (start[1]..finish[1])
        chapters.each do |chapter|
          passages << [book, chapter]
        end
      end
      passages.uniq.each do |book, chapter|
        chapter_files[book][chapter] << article
      end
    end

    chapter_files.each do |book, hash|
      filename = "chapters/#{book}.json"
      puts "==> #{filename}"
      File.write(filename, my_pretty_json(hash, 3, -1))
    end

  end
end




