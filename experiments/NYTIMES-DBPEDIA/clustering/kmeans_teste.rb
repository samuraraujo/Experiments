require 'rubygems'
require 'k_means'
require '../../../active_rdf/lib/active_rdf'
require '../../../activerdf_sparql-1.3.6/lib/activerdf_sparql/init'
require '../../endpoints.rb'

def mount_adapter(endpoint, method=:post,cache=true)

  adapter=nil
  begin
    adapter = ConnectionPool.add_data_source :type => :sparql, :engine => :virtuoso, :title=> endpoint , :url =>  endpoint, :results => :sparql_xml, :caching => cache , :request_method => method

  rescue Exception => e
    puts e.getMessage()
    return nil
  end
  return adapter
end

origin_endpoint=$endpoints[:nytimes]
e=mount_adapter(origin_endpoint,:post,false)
instances =  Query.new.adapters(e).sparql("select distinct ?s ?a ?b where {?s ?p <http://data.nytimes.com/elements/nytd_geo> . ?s <http://www.w3.org/2003/01/geo/wgs84_pos#lat> ?a . ?s <http://www.w3.org/2003/01/geo/wgs84_pos#long> ?b}").execute
data=[]
puts instances.size
instances.each{|x|
  data << [x[1].to_f,x[2].to_f]
}

kmeans = KMeans.new(data, :centroids => 20)
puts kmeans.inspect  # Use kmeans.view to get hold of the un-inspected array

