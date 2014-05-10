
require 'nokogiri'
require 'commander/import'
require 'uri'
require 'json'
require_relative 'my_pretty_json'

program :name, 'ODB Xref'
program :description, 'Creates cross-reference index for Our Daily Bread'
program :version, '0.0'

# Returns the cache filename for a cache key...
def cache_filename(key)
  "cache/#{key}.cache"
end

# A helper for caching...
def cached(key)
  filename = cache_filename(key)
  if File.exist?(filename)
    yield true, filename
  else
    yield false, filename
  end
end

# Cached HTTP request...
def fetch(key, url)
  cached key do |hit, filename|
    if hit
      puts "#{key}: CACHE HIT #{filename}"
    else
      puts "#{key}: #{url} => #{filename}"
      if system "curl --compressed -g '#{url}' -o '#{filename}.tmp'"
        File.rename("#{filename}.tmp", filename)
      else
        raise "Cannot download file!!"
      end
      sleep 0.3 + rand * 2.7
    end
    Nokogiri::HTML(File.read(filename))
  end
end

# Fetches an article index of a specified month...
def index(year, month)
  year  = year.to_i
  month = month.to_i
  url = "http://odb.org/%04d/%02d/api/posts_per_page/-1/sort[post_date]/DESC/" % [year, month]
  key = "index-%04d-%02d" % [year, month]
  page = fetch(key, url)
  output = []
  page.css('.type-post.status-publish').each do |element|
    link = element.css('h3.entry-title a').first
    href = link["href"]
    text = link.content
    if href =~ /(\d+)\/(\d+)\/(\d+)/
      date = [$1, $2, $3].map(&:to_i)
      output << { :date => date, :url => href, :title => text }
    end
  end
  return { :year => year, :month => month, :list => output }
end

# From a list of elements, find the text of Bible verse reference.
def find_verse_reference(list)
  list.map(&method(:get_verse_reference)).first
end

def get_verse_reference(element)
  link = element.css('a[href^="http://www.biblegateway.com/"]').last
  if link
    link.content
  else
    match = element.content.match(/(?:Read:\s+|—)(.*?)\S*\Z/)
    if match
      match[1]
    else
      raise "No verse reference found: #{element.content.inspect}"
    end
  end
end

# Fetchs an article by fetching the page and taking only the <article> element.
# This reduces the size of the cache by about 90%.
def fetch_article(key, url)
  cached "article-#{key}" do |hit, filename|
    unless hit
      page = fetch(key, url).css('article').first
      File.write(filename, page.to_html)
      File.unlink(cache_filename(key))
    end
    Nokogiri::HTML(File.read(filename))
  end
end

# From a list of links, returns the text along with its slug,
# matched using the `slug` regular expression.
# It is used to extract categories and tags.
def extract_name_slug(elements, slug)
  elements.map { |element| [element.content, element['href'].match(slug)[1]] }
end

# Scrapes a single article and return the information about that article,
# and the Bible passages.
def read(task)
  key = "post-%04d-%02d-%02d" % task[:date]
  url = task[:url]
  page = fetch_article(key, url)
  info = { }
  info[:title] = page.css('h1.entry-title').first.content
  author = page.css('.entry-meta .entry-author a').first
  info[:author] = [author.content, author['href'][/[^\/]+\/?$/]]
  meta_boxes = page.css('.meta-box')
  info[:passage] = find_verse_reference(meta_boxes.select { |c| c.content =~ /Read/ })
  info[:quote] = find_verse_reference(meta_boxes.select { |c| c.content =~ /—/ })
  info[:tags] = extract_name_slug(page.css('.tag-links a[rel="tag"]'), /\/tag\/([^\/]+)/)
  info[:categories] = extract_name_slug(page.css('.cat-links a[rel="category tag"]'), /\/category\/(.+)/)
  puts "   by #{info[:author]}, passage #{info[:passage]}"
  puts "   tags #{info[:tags]}"
  return task.merge(info)
rescue => e
  puts "!!! ERROR PROCESSING #{task[:url]}"
  raise e
end

command :archive do |c|
  c.action do |args, options|
    result = index(*args)
    archive = { :year => result[:year], :month => result[:month], :articles => [] }
    result[:list].each do |item|
      puts "=> #{item[:date].inspect} \e[1;33m#{item[:title]}\e[0m"
      archive[:articles] << read(item)
    end
    filename = "archive/%04d-%02d.json" % [result[:year], result[:month]]
    puts "=> Written to \e[1;32m#{filename}\e[0m"
    notify "Archived #{filename}"
    File.write(filename, my_pretty_json(archive, 3, -1))
  end
end

command :test_read do |c|
  c.action do |args, options|
    task = {:date=>[2014, 4, 30], :url=>"http://odb.org/2014/04/30/too-late/", :title=>"Too Late"}
    p read(task)
  end
end

require_relative 'odbxref_data'


