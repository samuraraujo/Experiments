require '../../active_rdf/lib/active_rdf'
require '../../activerdf_sparql-1.3.6/lib/activerdf_sparql/init'
require '../endpoints.rb'

$session = Hash.new

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

# $session[:origin] = mount_adapter($endpoints[:dbpedia] ,:post,false)
$session[:origin] = mount_adapter($endpoints[:freebase] ,:post,false)

def count(cluster)
  instances = Array.new
File.open(cluster, 'r').each { |s|
    instances << Query.new.adapters($session[:origin]).sparql("select ?p ?o where {  <#{s.to_s.rstrip}> ?p ?o }").execute
  }

puts instances[0].size
  puts instances[1].size

instances.each{|x|
    x.map!{|p,o| p.to_s + " " + o.to_s}
  }

puts instances[0] & instances[1]

end
def teste
   puts Query.new.adapters($session[:origin]).sparql("SELECT DISTINCT ?s WHERE { ?s <http://rdf.freebase.com/ns/type.object.name>   'Alaska'@en . } limit 30").execute
 
end
# count("./cluster.txt")
teste()
