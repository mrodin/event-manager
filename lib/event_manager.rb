require 'csv'
require 'sunlight/congress'
require 'erb'

Sunlight::Congress.api_key = 'e179a6973728c4dd3fb1204283aaccb5'

def clean_phone_number(number)
  raw_number = number.gsub(/\D/, '')

  if raw_number.length == 10 || (raw_number.length == 11 && raw_number[0] == '1')
    raw_number.rjust(11, '1')[1..10]
  else
    '0000000000'
  end
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir('output') unless Dir.exist? 'output'

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager Initialized!'

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol

template_letter = File.read 'form_letter.erb'
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone = clean_phone_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  puts "#{id} #{name} #{zipcode} #{phone}"
  save_thank_you_letters(id, form_letter)
end