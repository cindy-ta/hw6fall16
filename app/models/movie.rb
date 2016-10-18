class Movie < ActiveRecord::Base
  def self.all_ratings
    %w(G PG PG-13 NC-17 R)
  end

  class Movie::InvalidKeyError < StandardError ; end

  def self.find_in_tmdb(string)
    begin
      Tmdb::Api.key('f4702b08c0ac6ea5b51425788bb26562')
      
      movies = Tmdb::Movie.find(string)
      movies_array = []
      if movies.blank?
        return movies_array
      else
        movies.each do |movie|
          usa_releases = Tmdb::Movie.releases(movie.id)['countries']
          if usa_releases.nil?
            return movies_array
          else
            usa_releases.each do |release|
              if release["iso_3166_1"] == "US"
                
                movies_hash = { :tmdb_id => movie.id, :rating => release["certification"], :title => movie.title, :release_date => release["release_date"] }
                
                if :rating.empty? || :rating.nil?
                  return movies_array
                else
                  movies_array.push(movies_hash)
                end
              end
            end
          end
        end
      end
      return movies_array
      
    rescue Tmdb::InvalidApiKeyError
      raise Movie::InvalidKeyError, 'Invalid Api Key'
    end
    
  end

  def self.create_from_tmdb(tmdb_id)
    begin
      movie_detail = Tmdb::Movie.detail(tmdb_id)
      if movie_detail.nil?
        return []
      else
        rating = Tmdb::Movie.releases(tmdb_id)["countries"].select { |release| release['iso_3166_1'] == 'US'}[0]["certification"]
        movie_hash = { :title => movie_detail["title"], :rating => rating, :release_date => movie_detail["release_date"], :description => movie_detail["overview"] }
        Movie.create(movie_hash)
      end
    end
  end
end