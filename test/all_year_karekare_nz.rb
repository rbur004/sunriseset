#!/usr/local/bin/ruby
require 'sunriseset'
require 'date'

#Print sunrise date, time, sunset date, time for 2016 at Karekare, NZ.

latitude = -36.991
longitude = 174.487

(DateTime.new(2016, 01, 01)..DateTime.new(2016, 12, 31)).each do |date|
  vc = SunRiseSet.new(date, latitude,longitude)
  puts "#{vc.sunrise.new_offset('NZST').to_s.split(/[T\+]/).join("\t")}\t#{vc.sunset.new_offset('NZST').to_s.split(/[T\+]/).join("\t")}"
end
