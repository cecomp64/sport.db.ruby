# encoding: utf-8

module SportDb
  module FixtureHelpers


  def find_ground!( line )
    TextUtils.find_key_for!( 'ground', line )
  end

  ## todo/fix: pass in known_grounds as a parameter? why? why not?
  def map_ground!( line )
    TextUtils.map_titles_for!( 'ground', line, @known_grounds )
  end


  def find_track!( line )
    TextUtils.find_key_for!( 'track', line )
  end

  ## todo/fix: pass in known_tracks as a parameter? why? why not?
  def map_track!( line )
    TextUtils.map_titles_for!( 'track', line, @known_tracks )
  end

  def find_person!( line )
    puts "+++ Debug: find_person line: #{line}"
    key = TextUtils.find_key_for!( 'person', line )
    
    # Try looking for a different format
    #   [POS] -- First Last
    #   TODO: Reuse code in squad reader for parsing line format
    if (key.nil?)
      if (line =~ /\[POS\] (\S\S )?(\S+( \S+)?)/)
        if (Person.find_by_name($2))
          # Create a key out of the name in $2
          key = TextUtils.title_to_key( $2 )
          puts "+++ Debug: find_person alternate key: #{key}"
        end
      end
    end
    return key
  end

  def map_person!( line )
    TextUtils.map_titles_for!( 'person', line, @known_persons)
  end


  end # module FixtureHelpers
end # module SportDb

