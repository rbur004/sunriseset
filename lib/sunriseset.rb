require 'date'

#Calculates the sun rise and sunset times, with civil, naval and astronomical twilight values.
#Not sure of the origin of the code.
#I have seen a fortran version http://www.srrb.noaa.gov/highlights/sunrise/program.txt
#a .pl www.mso.anu.edu.au/~brian/grbs/astrosubs.pl
#and .vb versions too. 
#All had the same comments, so are of a common origin.
class SunRiseSet
  VERSION = '0.9.2'
  
  #because I live here
  LATITUDE_DEFAULT= -(36.0 + 59.0/60.0 + 27.60/3600) 
  LONGITUDE_DEFAULT= (174.0 + 29/60.0 + 13.20/3600) 

  #In degrees from the Zenith. Represents the Time when we turn car lights on and off
  CIVIL_TWILIGHT=96   
  #In degrees from the Zenith. Represents the Time when we can see the first light (dawn)
  NAVAL_TWILIGHT=102  
  #In degrees from the Zenith. Represents the Time when the sun is not interfering with viewing distant stars.
  ASTRO_TWILIGHT=108  
  #0.833 is allowing for the bending in the atmosphere.
  SUN_RISE_SET=90.833 

  # @return [DateTime] Naval Twilight begins (Sun is begining to lighten the sky )
  attr_reader :astroTwilightStart
  # @return [DateTime] Naval Twilight begins
  attr_reader :navalTwilightStart
  # @return [DateTime] Civil Twilight begins
  attr_reader :civilTwilightStart
  # @return [DateTime] Sun rise
  attr_reader :sunrise
  
  # @return [DateTime] Sun set
  attr_reader :sunset
  # @return [DateTime] End of Civil Twilight
  attr_reader :civilTwilightEnd
  # @return [DateTime] end of naval twilight
  attr_reader :navalTwilightEnd
  # @return [DateTime] end of astronomical twilight (sky is now fully dark)
  attr_reader :astroTwilightEnd

  # @return [DateTime] Sun is at the midpoint for today (varies throughout the year)
  attr_reader :solNoon
    
  
  # @return [SunRiseSet] Constructor for any datetime and location
  # @param [DateTime, #jd, #offset] datetime
  # @param [Float] latitude
  # @param [Float] longitude
  def initialize(datetime, latitude=LATITUDE_DEFAULT, longitude=LONGITUDE_DEFAULT)
    @latitude, @longitude = latitude, longitude
    @julian_date = DateTime.jd(datetime.jd.to_f)
    @julian_day = @julian_date.jd.to_f #Shorthand for later use, where we want this value as a float.
    @zone = datetime.offset #datetime.utc_offset/86400 #time zone offset + daylight savings as a fraction of a day
    calcSun
  end

  # @return [SunRiseSet] Constructor for date == today, at location specified
  # @param [Float] latitude
  # @param [Float] longitude
  def self.today(latitude=LATITUDE_DEFAULT, longitude=LONGITUDE_DEFAULT)
    self.new(DateTime.now, latitude, longitude)
  end
        
  # @return [SunRiseSet] Constructor for date == today, at location specified
  # @param [Float] latitude
  # @param [Float] longitude
  def self.now(latitude=LATITUDE_DEFAULT, longitude=LONGITUDE_DEFAULT)
    self.new(DateTime.now, latitude, longitude)
  end

  def time_format(t)
    if t == nil
      "Not Found"
    else
      t.strftime('%H:%M:%S %d-%m')
    end
  end
  
  # @return [String] dumps key attributes as a multiline string
  def to_s
    "Astro Twilight #{time_format(@astroTwilightStart)}\n" +
    "Naval Twilight #{time_format(@navalTwilightStart)}\n" +
    "Civil Twilight #{time_format(@civilTwilightStart)}\n" +
    "Sun Rises #{time_format(@sunrise)}\n" +
    "Solar noon  #{time_format(@solNoon)}\n" +
    "Sun Sets #{time_format(@sunset)}\n" +
    "End of Civil Twilight  #{time_format(@civilTwilightEnd)}\n" +
    "Naval Twilight #{time_format(@navalTwilightEnd)}\n" +
    "Astro Twilight #{time_format(@astroTwilightEnd)}\n" 
  end
  
  # @return [String] the constant VERSION
  def version
    VERSION
  end
  
  private
  
  # calculate time of sunrise and sunset for the entered date
  #    and location.  In the special cases near earth's poles,
  #    the date of nearest sunrise and set are reported.
  # @return [nil] fills in class DateTime attributes
  # :sunrise, :civilTwilightStart, :navalTwilightStart, :astroTwilightStart
  # :sunset, :civilTwilightEnd, :navalTwilightEnd and :astroTwilightEnd
  
  def calcSun

      # Calculate sunrise for this date
      # if no sunrise is found, set flag nosunrise

      @sunrise = calcSunriseUTC(@julian_day)
      @civilTwilightStart = calcSunriseUTC( @julian_day, CIVIL_TWILIGHT)
      @navalTwilightStart = calcSunriseUTC( @julian_day, NAVAL_TWILIGHT)
      @astroTwilightStart = calcSunriseUTC( @julian_day, ASTRO_TWILIGHT)
      
      # Calculate sunset for this date
      # if no sunrise is found, set flag nosunset
      @sunset = calcSunsetUTC(@julian_day)
      @civilTwilightEnd = calcSunsetUTC( @julian_day, CIVIL_TWILIGHT)
      @navalTwilightEnd = calcSunsetUTC( @julian_day, NAVAL_TWILIGHT)
      @astroTwilightEnd = calcSunsetUTC( @julian_day, ASTRO_TWILIGHT)

      # Calculate solar noon for this date
      t = calcTimeJulianCent( @julian_day )
      
      @solNoon = to_datetime(@julian_day, calcSolNoonUTC(t))

      # No sunrise or sunset found for today
      doy = @julian_date.yday
      if(@sunrise == nil)
        if ( ((@latitude > 66.4) && (doy > 79) && (doy < 267)) ||
           ((@latitude < -66.4) && ((doy < 83) || (doy > 263))) )
           # if Northern hemisphere and spring or summer, OR
           # if Southern hemisphere and fall or winter, use
           # previous sunrise and next sunset
          newjd = findRecentSunrise(@julian_day, @latitude, @longitude)
          @sunrise = calcSunriseUTC(newjd) + @zone
        elsif ( ((@latitude > 66.4) && ((doy < 83) || (doy > 263))) ||
          ((@latitude < -66.4) && (doy > 79) && (doy < 267)) )
          # if Northern hemisphere and fall or winter, OR
          # if Southern hemisphere and spring or summer, use
          # next sunrise and previous sunset
          newjd = findNextSunrise(@julian_day, @latitude, @longitude)
          @sunrise = calcSunriseUTC(newjd) + @zone
        else
          raise "Cannot Find Sunrise!"
        end

      end

      if(@sunset == nil)
        if ( ((@latitude > 66.4) && (doy > 79) && (doy < 267)) ||
          ((@latitude < -66.4) && ((doy < 83) || (doy > 263))) )
          # if Northern hemisphere and spring or summer, OR
          # if Southern hemisphere and fall or winter, use
          # previous sunrise and next sunset
          newjd = findNextSunset(@julian_day, @latitude, @longitude)
          @sunset = calcSunsetUTC(newjd) + @zone
        elsif ( ((@latitude > 66.4) && ((doy < 83) || (doy > 263))) ||
          ((@latitude < -66.4) && (doy > 79) && (doy < 267)) )
          # if Northern hemisphere and fall or winter, OR
          # if Southern hemisphere and spring or summer, use
          # next sunrise and last sunset
          newjd = findRecentSunset(@julian_day, @latitude, @longitude)
          @sunset = calcSunsetUTC(newjd) + @zone
        else
          raise "Cannot Find Sunset!"
        end
      end
  end
    
  # @param [Float] radian 
  # @return [Float] angle in degrees
  def radToDeg(angleRad)
    return (180.0 * angleRad / Math::PI)
  end

  # @param [Float] degrees 
  # @return [Float] angle in radians
  def degToRad(angleDeg)
    return (Math::PI * angleDeg / 180.0)
  end

  # convert Julian Day to centuries since J2000.0.
  # @param [Float] julian_day Julian Day
  # @return [Float] T value corresponding to the Julian Day
  def calcTimeJulianCent(julian_day)
    (julian_day - 2451545.0)/36525.0
  end

  # convert centuries since J2000.0 to Julian Day.
  # @param [Float] t  number of Julian centuries since J2000.0
  # @return [Float] the Julian Day corresponding to the t value
  def calcJDFromJulianCent(t)
    t * 36525.0 + 2451545.0
  end

  # calculate the Geometric Mean Longitude of the Sun
  # @param [Float] t  number of Julian centuries since J2000.0
  # @return [Float] the Geometric Mean Longitude of the Sun in degrees
  def calcGeomMeanLongSun(t)
    l0 = 280.46646 + t * (36000.76983 + 0.0003032 * t)
    while(l0 > 360.0)
      l0 -= 360.0
    end
    while(l0 < 0.0)
      l0 += 360.0
    end
    return l0;    # in degrees
  end

  # Calculate the Geometric Mean Anomaly of the Sun
  # @param [Float] t  number of Julian centuries since J2000.0
  # @return [Float] the Geometric Mean Anomaly of the Sun in degrees
  def calcGeomMeanAnomalySun(t)
    357.52911 + t * (35999.05029 - 0.0001537 * t) #in degrees
  end

  # calculate the eccentricity of earth's orbit
  # @param [Float] t  number of Julian centuries since J2000.0
  # @return [Float] the unitless eccentricity
  def calcEccentricityEarthOrbit(t)
    0.016708634 - t * (0.000042037 + 0.0000001267 * t)  # unitless
  end

  # calculate the equation of center for the sun
  # @param [Float] t  number of Julian centuries since J2000.0
  # @return [Float] in degrees
  def calcSunEqOfCenter(t)

    m = calcGeomMeanAnomalySun(t)

    mrad = degToRad(m)
    sinm = Math.sin(mrad)
    sin2m = Math.sin(mrad+mrad)
    sin3m = Math.sin(mrad+mrad+mrad)

    sinm * (1.914602 - t * (0.004817 + 0.000014 * t)) + sin2m * (0.019993 - 0.000101 * t) + sin3m * 0.000289 # in degrees
  end

  # calculate the true longitude of the sun
  # @param [Float] t  number of Julian centuries since J2000.0
  # @return [Float] sun's true longitude in degrees
  def calcSunTrueLong(t)
    calcGeomMeanLongSun(t) + calcSunEqOfCenter(t) # in degrees
  end

  # calculate the true anamoly of the sun
  # @param [Float] t  number of Julian centuries since J2000.0
  # @return [Float] sun's true anamoly in degrees
  def calcSunTrueAnomaly(t)
    calcGeomMeanAnomalySun(t) + calcSunEqOfCenter(t)  # in degrees
  end

  # calculate the distance to the sun in AU
  # @param [Float] t  number of Julian centuries since J2000.0
  # @return [Float] sun radius vector in AUs
  def calcSunRadVector(t)
    v = calcSunTrueAnomaly(t)
    e = calcEccentricityEarthOrbit(t)
    (1.000001018 * (1.0 - e * e)) / (1.0 + e * Math.cos(degToRad(v))) # in AUs
  end

  # calculate the apparent longitude of the sun
  # @param [Float] t  number of Julian centuries since J2000.0
  # @return [Float] sun's apparent longitude in degrees
  def calcSunApparentLong(t)
    o = calcSunTrueLong(t)
    omega = 125.04 - 1934.136 * t
    o - 0.00569 - 0.00478 * Math.sin(degToRad(omega)) # in degrees
  end

  # calculate the mean obliquity of the ecliptic
  # @param [Float] t  number of Julian centuries since J2000.0
  # @return [Float] mean obliquity in degrees
  def calcMeanObliquityOfEcliptic(t)
    seconds = 21.448 - t*(46.8150 + t*(0.00059 - t*(0.001813)))
    23.0 + (26.0 + (seconds/60.0))/60.0   # in degrees
  end

  # calculate the corrected obliquity of the ecliptic
  # @param [Float] t  number of Julian centuries since J2000.0
  # @return [Float] corrected obliquity in degrees
  def calcObliquityCorrection(t)
    e0 = calcMeanObliquityOfEcliptic(t)
    omega = 125.04 - 1934.136 * t
    e0 + 0.00256 * Math.cos(degToRad(omega))    # in degrees
  end

  # calculate the right ascension of the sun
  # @param [Float] t  number of Julian centuries since J2000.0
  # @return [Float] sun's right ascension in degrees
  def calcSunRtAscension(t)
    e = calcObliquityCorrection(t)
    lambda = calcSunApparentLong(t)
    tananum = (Math.cos(degToRad(e)) * Math.sin(degToRad(lambda)))
    tanadenom = (Math.cos(degToRad(lambda)))
    radToDeg(Math.atan2(tananum, tanadenom))  # in degrees
  end

  # calculate the declination of the sun
  # @param [Float] t  number of Julian centuries since J2000.0
  # @return [Float] sun's declination in degrees
  def calcSunDeclination(t)
    e = calcObliquityCorrection(t)
    lambda = calcSunApparentLong(t)
    sint = Math.sin(degToRad(e)) * Math.sin(degToRad(lambda))
    radToDeg(Math.asin(sint)) # in degrees
  end

  # calculate the difference between true solar time and mean solar time
  # @param [Float] t  number of Julian centuries since J2000.0
  # @return [Float] equation of time in minutes of time
  def calcEquationOfTime(t)
    epsilon = calcObliquityCorrection(t)
    l0 = calcGeomMeanLongSun(t)
    e = calcEccentricityEarthOrbit(t)
    m = calcGeomMeanAnomalySun(t)

    y = Math.tan(degToRad(epsilon)/2.0)
    y *= y

    sin2l0 = Math.sin(2.0 * degToRad(l0))
    sinm   = Math.sin(degToRad(m))
    cos2l0 = Math.cos(2.0 * degToRad(l0))
    sin4l0 = Math.sin(4.0 * degToRad(l0))
    sin2m  = Math.sin(2.0 * degToRad(m))

    radToDeg(y * sin2l0 - 2.0 * e * sinm + 4.0 * e * y * sinm * cos2l0 -
                0.5 * y * y * sin4l0 - 1.25 * e * e * sin2m)*4.0  # in minutes of time
  end

  # calculate the hour angle of the sun at sunrise for the latitude
  # @param [Float] solarDec  declination angle of sun in degrees
  # @param [SUN_RISE_SET,CIVIL_TWILIGHT,NAVAL_TWILIGHT,ASTRO_TWILIGHT] angle
  # @return [Float] hour angle of sunrise in radians
  #  0.833 is an approximation of the reflaction caused by the atmosphere
  def calcHourAngleSunrise(solarDec, angle=SUN_RISE_SET)
    latRad = degToRad(@latitude) 
    sdRad  = degToRad(solarDec)
    #puts "latRad = #{radToDeg(latRad)}, sdRad = #{radToDeg(sdRad)}, angle = #{angle}"

    #ha_arg = Math.cos(degToRad(angle + 0.833))/(Math.cos(latRad)*Math.cos(sdRad))-Math.tan(latRad) * Math.tan(sdRad)
    ha_arg = Math.cos(degToRad(angle))/
            (Math.cos(latRad)*Math.cos(sdRad)) - Math.tan(latRad) * Math.tan(sdRad)
    Math.acos(ha_arg)  # in radians
  end

  # calculate the hour angle of the sun at sunset for the
  # @param [Float] solarDec  declination angle of sun in degrees
  # @param [SUN_RISE_SET,CIVIL_TWILIGHT,NAVAL_TWILIGHT,ASTRO_TWILIGHT] angle
  # @return [Float]  hour angle of sunset in radians
  def calcHourAngleSunset( solarDec, angle=SUN_RISE_SET)
    -calcHourAngleSunrise(solarDec,angle)   # in radians
  end

  # calculate the Universal Coordinated Time (UTC) of sunrise
  #      for the given day at the given location on earth
  # @param [Float] julian_day
  # @param [SUN_RISE_SET,CIVIL_TWILIGHT,NAVAL_TWILIGHT,ASTRO_TWILIGHT] angle
  # @return [DateTime]  Date and Time of event
  def calcSunriseUTC( julian_day, angle=SUN_RISE_SET)
    begin
      t = calcTimeJulianCent( julian_day )

      # *** Find the time of solar noon at the location, and use
          #     that declination. This is better than start of the
          #     Julian day

      noonmin = calcSolNoonUTC(t)
      tnoon = calcTimeJulianCent( julian_day+noonmin/1440.0)

      # *** First pass to approximate sunrise (using solar noon)

      eqTime = calcEquationOfTime(tnoon)
      solarDec = calcSunDeclination(tnoon)
      hourAngle = calcHourAngleSunrise(solarDec,angle)
      delta =  -@longitude - radToDeg(hourAngle)
      timeDiff = 4 * delta; # in minutes of time
      timeUTC = 720 + timeDiff - eqTime;  # in minutes

      # *** Second pass includes fractional jday in gamma calc

      newt = calcTimeJulianCent(calcJDFromJulianCent(t) + timeUTC/1440.0)
      eqTime = calcEquationOfTime(newt)
      solarDec = calcSunDeclination(newt)
      hourAngle = calcHourAngleSunrise(solarDec,angle)
      delta = -@longitude - radToDeg(hourAngle)
      timeDiff = 4 * delta
      timeUTC = 720 + timeDiff - eqTime; # in minutes

      to_datetime(julian_day,timeUTC)
    rescue Math::DomainError => error
      return nil #didn't find a Sunrise today. Will be raised by 
    end
  end

  # calculate the Universal Coordinated Time (UTC) of solar
  #    noon for the given day at the given location on earth
  # @param [Float] t  number of Julian centuries since J2000.0
  # @return [Float] time in minutes from zero Z
  def calcSolNoonUTC(t)
    # First pass uses approximate solar noon to calculate eqtime
    tnoon = calcTimeJulianCent(calcJDFromJulianCent(t) - @longitude/360.0)
    eqTime = calcEquationOfTime(tnoon)
    solNoonUTC = 720 - (@longitude * 4) - eqTime; # min

    newt = calcTimeJulianCent(calcJDFromJulianCent(t) -0.5 + solNoonUTC/1440.0)

    eqTime = calcEquationOfTime(newt)
    solNoonUTC = 720 - (@longitude * 4) - eqTime; # min

    return solNoonUTC
  end

  # calculate the Universal Coordinated Time (UTC) of sunset
  #      for the given day at the given location on earth
  # @param [Float] julian_day
  # @param [SUN_RISE_SET,CIVIL_TWILIGHT,NAVAL_TWILIGHT,ASTRO_TWILIGHT] angle
  # @return [DateTime]  Date and Time of event
  def calcSunsetUTC(julian_day, angle=SUN_RISE_SET)
    begin
      t = calcTimeJulianCent(julian_day)

      # *** Find the time of solar noon at the location, and use
          #     that declination. This is better than start of the
          #     Julian day

      noonmin = calcSolNoonUTC(t)
      tnoon = calcTimeJulianCent(julian_day+noonmin/1440.0)

      # First calculates sunrise and approx length of day

      eqTime = calcEquationOfTime(tnoon)
      solarDec = calcSunDeclination(tnoon)
      hourAngle = calcHourAngleSunset(solarDec, angle)

      delta = -@longitude - radToDeg(hourAngle)
      timeDiff = 4 * delta
      timeUTC = 720 + timeDiff - eqTime

      # first pass used to include fractional day in gamma calc

      newt = calcTimeJulianCent(calcJDFromJulianCent(t) + timeUTC/1440.0)
      eqTime = calcEquationOfTime(newt)
      solarDec = calcSunDeclination(newt)
      hourAngle = calcHourAngleSunset(solarDec, angle)

      delta = -@longitude - radToDeg(hourAngle)
      timeDiff = 4 * delta
      timeUTC = 720 + timeDiff - eqTime; # in minutes

      to_datetime(julian_day,timeUTC)
    rescue Math::DomainError => error
      return nil # no Sunset
    end
  end

  # calculate the julian day of the most recent sunrise
  #    starting from the given day at the given location on earth
  # @param [Float] julianday
  # @return [Float]  julian day of the most recent sunrise
  def findRecentSunrise(julianday)
    time = calcSunriseUTC(julianday)
    while(!isNumber(time))
      julianday -= 1.0
      time = calcSunriseUTC(julianday)
    end

    return julianday
  end

  # calculate the julian day of the most recent sunset
  #    starting from the given day at the given location on earth
  # @param [Float] julianday
  # @return [Float]  julian day of the most recent sunset
  def findRecentSunset(julianday)
    time = calcSunsetUTC(julianday)
    while(!isNumber(time))
      julianday -= 1.0
      time = calcSunsetUTC(julianday)
    end

    return julianday
  end

  # calculate the julian day of the next sunrise
  #    starting from the given day at the given location on earth
  # @param [Float] julianday
  # @return [Float]  julian day of the next sunrise
  def findNextSunrise(julianday)
    time = calcSunriseUTC(julianday)
    while(!isNumber(time))
      julianday += 1.0
      time = calcSunriseUTC(julianday)
    end

    return julianday
  end

  # calculate the julian day of the next sunset
  #    starting from the given day at the given location on earth
  # @param [Float] julianday
  # @return [Float]  julian day of the next sunset
  def findNextSunset(julianday)
    time = calcSunsetUTC(julianday)
    while(!isNumber(time))
      julianday += 1.0
      time = calcSunsetUTC(julianday)
    end

    return julianday
  end

  # convert julian day and minutes to datetime
  # @param [Float] minutes
  # @return [DateTime] 
  def to_datetime(x,minutes)
    jd = DateTime.jd(@julian_day)  + (minutes/1440.0)  + @zone 
  end
  
end

