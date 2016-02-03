require 'csv'
require 'sunlight/congress'
require 'erb'

Sunlight::Congress.api_key = 'e179a6973728c4dd3fb1204283aaccb5'

def convert_date(date_str)
  DateTime.strptime(date_str, '%m/%d/%y %H:%M')
end

def get_weekday_name(date_str)
  convert_date(date_str).strftime('%A')
end

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

def count_date_values(date_value, target_hash)
  if target_hash.has_key?(date_value)
    target_hash[date_value] += 1
  else
    target_hash[date_value] = 1
  end
  target_hash
end

puts 'EventManager Initialized!'

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol

template_letter = File.read 'form_letter.erb'
erb_template = ERB.new template_letter

reg_hours = Hash.new
reg_days = Hash.new

contents.each do |row|
  id = row[0]
  date = convert_date(row[:regdate])
  weekday = get_weekday_name(row[:regdate])
  name = row[:first_name]
  phone = clean_phone_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])

  count_date_values(date.hour, reg_hours)
  count_date_values(weekday, reg_days)

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  puts "#{id} #{name} #{zipcode} #{phone}"
  save_thank_you_letters(id, form_letter)
end

busiest_hour = reg_hours.max_by { |k, v| v }[0]
puts "Busiest registration hour is #{busiest_hour}."

busiest_day = reg_days.max_by { |k, v| v }[0]
puts "Busiest registration day is #{busiest_day}."