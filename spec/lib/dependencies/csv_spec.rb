require 'rails_helper'
RSpec.describe CSV do
  it 'overrides the default CSV version to use versions with proper BOM parsing' do
    expect(CSV::VERSION).to eq('3.1.2')
    csv = CSV.generate_line(%i[ asdf fdsa qwer rewq ])
    20.times do
      csv << CSV.generate_line(%w[ asdf fdsa qwer rewq ])
    end
    csv_path = BetterRecord::Engine.root.join('spec', 'tmp', 'encoding_test.csv')
    File.open(csv_path, 'wb') do |file|
      file.write(BetterRecord::Encoder.new(csv).to_utf8)
    end
    expect { CSV.foreach(csv_path, headers: true, encoding: 'bom|utf-8') {|row| row } }.to_not raise_error
    expect { CSV.foreach(csv_path, headers: true, encoding: 'bom|asdf') {|row| row } }.to write(/nonsense/).to(:stderr)
  end
end
