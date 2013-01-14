#!/usr/local/bin/ruby
require 'date'
require 'rubygems'
require 'sunriseset'

today = SunRiseSet.today(-36.991,174.487)

if ARGV.length == 0
  print <<EOF
<html>
<head>
<title>Sun Times</title>
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
<META HTTP-EQUIV="Refresh" CONTENT="3600;URL=sunriseset.html">
</head>
<body>
  <b>Astro Twilight</b> #{today.astroTwilightStart.strftime('%H:%M')}
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
  <b>Naval Twilight</b> #{today.navalTwilightStart.strftime('%H:%M')}
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
  <b>CivilTwilight</b> #{today.civilTwilightStart.strftime('%H:%M')}<br>
  <b>Sun Rises</b> #{today.sunrise.strftime('%H:%M')}
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
  <b>Solar noon</b> #{today.solNoon.strftime('%H:%M:%S')}
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <b>Sun Sets</b> #{today.sunset.strftime('%H:%M')}<br>
  <b>End of Civil Twilight</b> #{today.civilTwilightEnd.strftime('%H:%M')}
    &nbsp;&nbsp; 
  <b>Naval Twilight</b> #{today.navalTwilightEnd.strftime('%H:%M')}
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
  <b>Astro Twilight</b> #{today.astroTwilightEnd.strftime('%H:%M')}<br>
</body>
</html>
EOF
elsif ARGV[0] == "--rs"
  print <<EOF2
<html>
<head>
<title>Sun Rise/Set</title>
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
<META HTTP-EQUIV="Refresh" CONTENT="3600;URL=sun_rs.html">
</head>
<body>
  &nbsp;&nbsp;Sun Rises at #{today.sunrise.strftime('%H:%M')} Sets at #{today.sunset.strftime('%H:%M')}
</body>
</html>
EOF2
end
