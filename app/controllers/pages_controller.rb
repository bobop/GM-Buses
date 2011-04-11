class PagesController < ApplicationController
  def home
    response = RestClient.get("http://linkedmanchester.org/datasets/buses/routes.json")
    @routes = JSON.parse(response.body)
  end
  
  def service
    
    query = "
    PREFIX transit: <http://vocab.org/transit/terms/>
    PREFIX naptan: <http://transport.data.gov.uk/def/naptan/>
    PREFIX geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

    SELECT distinct(?stop) ?label ?lat ?long WHERE {
    GRAPH <http://linkedmanchester.org/id/graph/buses/gmpte> {
    ?trip transit:route <http://linkedmanchester.org/id/buses/route/#{params[:service][:number]}> .
    ?trip transit:stopTime ?stoptime .
    ?stoptime transit:stop ?stop .
    ?stop geo:lat ?lat .
    ?stop geo:long ?long .
    ?stop skos:prefLabel ?label
    }}
    "
    
    response = RestClient.get("http://linkedmanchester.org/sparql.json?_per_page=100&q=#{URI.encode(query)}")
    @stops = JSON.parse(response.body)
  end
  
  def times
    @query = "
    PREFIX transit: <http://vocab.org/transit/terms/>

    SELECT
     ?stoptime ?depTime ?arrTime

    WHERE {
    # substitute 1800SB... for the stop id
     ?stoptime transit:stop <#{params['stop_uri']}> .
     ?stoptime <http://vocab.org/transit/terms/trip> ?trip .

    # substitute ...101 for the route id
     ?trip <http://vocab.org/transit/terms/route> <http://linkedmanchester.org/id/buses/route/#{params[:service_id]}> .
     ?trip <http://vocab.org/transit/terms/serviceCalendar> ?cal .

    # substitute /thursday for the right day of week
     ?cal transit:#{Time.now.strftime("%A").downcase} true .
    # only buses leaving from this stop
     ?stoptime transit:departureTime ?depTime

     OPTIONAL{?cal transit:startDate ?startDate }

     OPTIONAL{?cal transit:endDate ?endDate }

     # substitute literal date with current date
     FILTER (!bound(?startDate) || ?startDate <= \"#{Time.now.strftime("%Y-%m-%d")}\"^^<http://www.w3.org/2001/XMLSchema#date>) .
     FILTER (!bound(?endDate) || ?endDate >= \"#{Time.now.strftime("%Y-%m-%d")}\"^^<http://www.w3.org/2001/XMLSchema#date>) .

    }
    "
    #@alltimes = Hash
    #(1..10).each do |i|
    #  response = RestClient.get("http://linkedmanchester.org/sparql.json?_per_page=100&_page=#{i}&q=#{URI.encode(@query)}")
    #  @times = JSON.parse(response.body)
    #  @alltimes << @times
    #  if @times.size != 100
    #    return
    #  end
    #end
    response = RestClient.get("http://linkedmanchester.org/sparql.json?_per_page=100&_page=1&q=#{URI.encode(@query)}")
    @times = JSON.parse(response.body)
    
  end
end
