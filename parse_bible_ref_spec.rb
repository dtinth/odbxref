
require_relative 'parse_bible_ref'

describe BibleReference, '::parse' do
  
  example = proc do |input, output|
    it "should produce #{output.inspect} for #{input}" do
      expect(BibleReference.parse(input)).to eq(output)
    end
  end

  example[
    'Genesis 1:1-3', [
      [["gen", 1, 1], ["gen", 1, 3]]
    ]
  ]

  example[
    '3 John', [
      [["3jn", 1, nil]]
    ]
  ]

  example[
    'Ecclesiastes 2:26-3:8,11,4:13-14', [
      [["ecc", 2, 26], ["ecc", 3, 8]],
      [["ecc", 3, 11]],
      [["ecc", 4, 13], ["ecc", 4, 14]]
    ]
  ]

  example[
    'Psalm 117-118', [
      [["psa", 117, nil], ["psa", 118, nil]]
    ]
  ]

  example[
    '2 Kings 7-9; John 1:1-28', [
      [["2ki", 7, nil], ["2ki", 9, nil]],
      [["jhn", 1, 1], ["jhn", 1, 28]]
    ]
  ]

  example[
    'John 1:1-28; 2 Kings 7-9', [
      [["jhn", 1, 1], ["jhn", 1, 28]],
      [["2ki", 7, nil], ["2ki", 9, nil]]
    ]
  ]

end




