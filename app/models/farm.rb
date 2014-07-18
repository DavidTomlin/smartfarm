class Farm < ActiveRecord::Base
  has_paper_trail

  belongs_to :user

  validates_presence_of :user, :name, :latitude, :longitude, :data

  def to_svg
    @svg ||= generate_svg
  end

  def static_map_url
    ["http://maps.googleapis.com/maps/api/staticmap?", #key=AIzaSyAWk3UQFfLP1-q-VrLd46sKcZ-RyYMDfTM",
       "markers=color:red|#{latitude},#{longitude}",
       "zoom=13",
       "maptype=terrain",
       "size=600x300"
      ].join("&")
   end

private

  def generate_svg
    width = 300
    height = 200
    svg = "<svg width='#{width}' height='#{height}'>"

    farm_data = JSON.parse data
    north = farm_data["location"]["latitude"]
    south = farm_data["location"]["latitude"]
    east = farm_data["location"]["longitude"]
    west = farm_data["location"]["longitude"]

    # Find the outer boundaries of the simulations
    for bound in farm_data["field_bounds"]
      for corner in bound
        north = corner["latitude"] > north ? corner["latitude"] : north;
        south = corner["latitude"] < south ? corner["latitude"] : south;
        west = corner["longitude"] > west ? corner["longitude"] : west;
        east = corner["longitude"] < east ? corner["longitude"] : east;
      end
    end

    # Convert field bounds into pixel coordinates
    farm_data["field_bounds"].each_with_index do |bound, index|
      points = []
      left = width
      right = 0
      top = 0
      bottom = height
      for corner in bound
        x = (corner["longitude"] - east) * (width / (west - east))
        y = height - (corner["latitude"] - south) * (height / (north - south))
        left = x < left ? x : left
        right = x > right ? x : right
        top = y > top ? y : top
        bottom = y < bottom ? y : bottom
        points << "#{x},#{y}"
      end
      svg << "<polygon data-field-index='#{ index }' points='#{ points.join(" ") }' style='stroke:black;stroke-width:5' />"
      svg << "<text x='#{left + ((right - left) / 2)}' y='#{bottom + ((top - bottom) / 2)}' font-family='Veranda' font-size='55'>#{ index }</text>"
    end
    svg << "</svg>"
  end

end
