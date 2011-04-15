class PagesController < ApplicationController
  def home
    query = "
    PREFIX transit: <http://vocab.org/transit/terms/>

    SELECT DISTINCT ?routeno WHERE {
    GRAPH <http://linkedmanchester.org/id/graph/buses/gmpte> { 
    ?route transit:routeShortName ?routeno .
    }}

    order by ?name
    "
    response = RestClient.get("http://linkedmanchester.org/sparql.json?_per_page=100&_page=1&q=#{URI.encode(query)}")
    @routes = JSON.parse(response.body)
    
    (2..5).each do |i|
      response2 = RestClient.get("http://linkedmanchester.org/sparql.json?_per_page=100&_page=#{i}&q=#{URI.encode(query)}")
      @routes2 = JSON.parse(response2.body)
      @routes2['results']['bindings'].each do |r|
        @routes['results']['bindings'].push(r)
      end
    end    
  end
  
  def route
    query = "
    PREFIX transit: <http://vocab.org/transit/terms/>
    PREFIX rdf: <http://www.w3.org/2000/01/rdf-schema#>

    SELECT DISTINCT ?cal ?description WHERE {
    GRAPH <http://linkedmanchester.org/id/graph/buses/gmpte> {
    ?trip transit:route <http://linkedmanchester.org/id/buses/route/#{params[:route]}> .
    ?trip transit:routeDescription ?description .
    ?trip transit:serviceCalendar ?cal .
    ?cal transit:#{Time.zone.now.strftime("%A").downcase} true .
    OPTIONAL{?cal transit:startDate ?startDate }
    OPTIONAL{?cal transit:endDate ?endDate }
    # substitute literal date with current date
    FILTER (!bound(?startDate) || ?startDate <= \"#{Time.zone.now.strftime("%Y-%m-%d")}\"^^<http://www.w3.org/2001/XMLSchema#date>) .
    FILTER (!bound(?endDate) || ?endDate >= \"#{Time.zone.now.strftime("%Y-%m-%d")}\"^^<http://www.w3.org/2001/XMLSchema#date>) .
    }}
    "
    
    response = RestClient.get("http://linkedmanchester.org/sparql.json?_per_page=100&q=#{URI.encode(query)}")
    @services = JSON.parse(response.body)
    #render :json => response.body
  end
  
  def stops
    query = "
    PREFIX transit: <http://vocab.org/transit/terms/>
    PREFIX naptan: <http://transport.data.gov.uk/def/naptan/>
    PREFIX geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdf: <http://www.w3.org/2000/01/rdf-schema#>

    SELECT distinct(?stop) ?label ?lat ?long ?slabel WHERE {
    GRAPH <http://linkedmanchester.org/id/graph/buses/gmpte> {
    ?trip transit:serviceCalendar <#{params[:cal_uri]}> .
    ?trip transit:stopTime ?stoptime .
    ?trip transit:serviceCalendar ?cal .
    ?cal rdf:label ?slabel .
    ?stoptime transit:stop ?stop .
    ?stop geo:lat ?lat .
    ?stop geo:long ?long .
    ?stop skos:prefLabel ?label
    }}
    "
    response = RestClient.get("http://linkedmanchester.org/sparql.json?_per_page=100&q=#{URI.encode(query)}")
    @stops = JSON.parse(response.body)
    #render :json => response.body
  end
  
  def service
    
    query = "
    PREFIX transit: <http://vocab.org/transit/terms/>
    PREFIX naptan: <http://transport.data.gov.uk/def/naptan/>
    PREFIX geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX rdf: <http://www.w3.org/2000/01/rdf-schema#>

    SELECT distinct(?stop) ?label ?lat ?long WHERE {
    GRAPH <http://linkedmanchester.org/id/graph/buses/gmpte> {
    ?trip transit:route <http://linkedmanchester.org/id/buses/route/#{params[:route]}> .
    ?trip transit:serviceCalendar ?cal .
    ?cal rdf:label ?slabel .
    ?trip transit:stopTime ?stoptime .
    ?stoptime transit:stop ?stop .
    ?stop geo:lat ?lat .
    ?stop geo:long ?long .
    ?stop skos:prefLabel ?label
    }}
    "
    
    response = RestClient.get("http://linkedmanchester.org/sparql.json?_per_page=100&q=#{URI.encode(query)}")
    @stops = JSON.parse(response.body)
    #render :json => response.body
  end
  
  def times
    @query = "
    PREFIX transit: <http://vocab.org/transit/terms/>
    PREFIX rdf: <http://www.w3.org/2000/01/rdf-schema#>

    SELECT
     ?stoptime ?depTime ?arrTime ?sclabel

    WHERE { GRAPH <http://linkedmanchester.org/id/graph/buses/gmpte> {
    # substitute 1800SB... for the stop id
     ?stoptime transit:stop <#{params['stop_uri']}> .
     ?stoptime <http://vocab.org/transit/terms/trip> ?trip .

    # substitute ...101 for the route id
    # ?trip <http://vocab.org/transit/terms/route> <http://linkedmanchester.org/id/buses/route/#{params[:route_id]}> .
     ?trip transit:serviceCalendar <#{params[:cal_uri]}> .
     ?trip <http://vocab.org/transit/terms/serviceCalendar> ?cal .

    # substitute /thursday for the right day of week
     ?cal transit:#{Time.zone.now.strftime("%A").downcase} true .
    # only buses leaving from this stop
     ?stoptime transit:departureTime ?depTime .
     
     ?cal rdf:label ?sclabel

     OPTIONAL{?cal transit:startDate ?startDate }

     OPTIONAL{?cal transit:endDate ?endDate }

     # substitute literal date with current date
     FILTER (!bound(?startDate) || ?startDate <= \"#{Time.zone.now.strftime("%Y-%m-%d")}\"^^<http://www.w3.org/2001/XMLSchema#date>) .
     FILTER (!bound(?endDate) || ?endDate >= \"#{Time.zone.now.strftime("%Y-%m-%d")}\"^^<http://www.w3.org/2001/XMLSchema#date>) .

    }}
    
    
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
    #render :json => response.body
  end
end
