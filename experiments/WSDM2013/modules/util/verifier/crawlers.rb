require  File.dirname(__FILE__)+ '/../../../../../active_rdf/lib/active_rdf'
require  File.dirname(__FILE__)+'/../../../../../activerdf_sparql-1.3.6/lib/activerdf_sparql/init'

def mount_adapter(endpoint, method=:post,cache=true)

  adapter=nil
  begin
    adapter = ConnectionPool.add_data_source :type => :sparql, :engine => :virtuoso, :title=> endpoint , :url =>  endpoint, :results => :sparql_xml, :caching => cache , :request_method => method

  rescue Exception => e
    puts e
    return nil
  end
  return adapter
end

def freebase_crawler
  require 'json'
  require 'net/http'
  #missing resources
  subjects=[]
  File.open("/Users/samuraraujo/Documents/tmp/missing-freebase-icde", 'r').each { |line|
    subjects << line.split("=")[0].rstrip
  }
  puts "FREEBASE CRAWLER"
  # puts subjects
  subjects.each{|s|
    puts s
    # classes = "<http://data.nytimes.com/elements/nytd_per>"
    # classes = "<http://data.nytimes.com/elements/nytd_des>"
    # classes = "<http://data.nytimes.com/elements/nytd_geo>"
    classes = "<http://data.nytimes.com/elements/nytd_org>"
    origin_endpoint = "http://localhost:8890/sparql?default-graph-uri=http://nytimes.org"
    session = mount_adapter(origin_endpoint,:post,false)
    result =  Query.new.adapters(session).sparql("select distinct ?x where {  <#{s}>   <http://www.w3.org/2004/02/skos/core#prefLabel> ?x }  ").execute
    # result =  Query.new.adapters(session[:origin]).sparql("select distinct ?x where {  <#{s}>   <http://www.w3.org/2002/07/owl#sameAs> ?x }  ").execute

    # result =  Query.new.adapters(session[:origin]).sparql("select distinct ?x where {?s ?p #{classes} . ?s <http://www.w3.org/2004/02/skos/core#prefLabel> ?x }  ").execute
    File.open("/Users/samuraraujo/tmp/freebase-missing-org-3.rdf", 'a') {|f|
      flag = true
      puts result.size
      count = 0
      result.each{|x|

        count = count +1
        puts count
        # next if count < 1920
        label= x[0].to_s
        puts "Processing ..."
        puts label
        url="http://api.freebase.com/api/service/search?query=#{CGI::escape(label)}"
        puts url
        resp = Net::HTTP.get_response(URI.parse(url))
        data = resp.body
        result = JSON.parse(data)

        result["result"][0..3].each{|x|
          id = x["id"]
          if id.index("/en/") != nil
            id = id.gsub("/en/","/en.")
            url ="http://rdf.freebase.com/rdf#{id}"
            puts url
            resp = Net::HTTP.get_response(URI.parse(url))
            data = resp.body

            f.write(data)
            f.write("\n" )
          end
        }

      }
    }
  }
  render :text => "teste"

end

def freebase_checkmissing
  require 'json'
  require 'net/http'
  #missing resources
  subjects=[]
  File.open("./freebasemissinggeo.txt", 'r').each { |line|
    subjects << line.split("=")[1].rstrip
  }
  puts "FREEBASE CRAWLER"
  # puts subjects
  missing = []
  subjects.each{|s|
    # puts s
   
    # origin_endpoint = "http://localhost:8895/sparql?default-graph-uri=http://freebase.org"
origin_endpoint = "http://localhost:8898/sparql?default-graph-uri=http://geonames.org"
    session= mount_adapter(origin_endpoint,:post,false)

    result =  Query.new.adapters(session).sparql("select distinct ?x where {  <#{s}>   ?p ?x }  ").execute
    puts result.size
     missing << s if result.size ==0  
  }
  puts missing

end

def freebase_crawler2
  require 'json'
  require 'net/http'
  #missing resources
  subjects=[]
  File.open("./missed.txt", 'r').each { |line|
    subjects << line.rstrip
  }
  puts "FREEBASE CRAWLER"
  # puts subjects
  subjects.each{|s|
    puts s
       File.open("./freebase-missing-people-31.rdf", 'a') {|f|
      flag = true
      
      count = 0
     
        x=s.to_s.gsub(">","").gsub("<","").gsub("/ns/","/rdf/")
        next if x.index("freebase") == nil
        puts x
        resp = Net::HTTP.get_response(URI.parse(x))
        data = resp.body

        f.write(data)
        f.write("\n" )

     
    }

  }

end

def enrichdata
  # require 'json'
  require 'net/http'
  classes = "<http://data.nytimes.com/elements/nytd_per>"
  # classes = "<http://data.nytimes.com/elements/nytd_des>"
  # classes = "<http://data.nytimes.com/elements/nytd_geo>"
  # classes = "<http://data.nytimes.com/elements/nytd_org>"
  origin_endpoint = "http://localhost:8890/sparql?default-graph-uri=http://nytimes.org"
  session[:origin] = mount_adapter(origin_endpoint,:post,false)

  result =  Query.new.adapters(session[:origin]).sparql("select distinct ?s ?x where {?s ?p #{classes} . ?s <http://data.nytimes.com/elements/topicPage> ?x } ").execute
  File.open("/Users/samuraraujo/tmp/alignment/enrich.nt", 'w') {|f|
    flag = true
    puts result.size
    count = 0
    result.each{|x|
      begin
        count = count +1
        puts count
        nytimespage= x[1].uri.to_s
        puts "Processing ..."
        puts nytimespage
        url="http://uclassify.com/browse/uClassify/Topics/ClassifyUrl?readkey=40MLCLxcTlz6HGPbL7uW5BfmfM&url=#{nytimespage}&version=1.01&removeHtml=1&output=json"
        resp = Net::HTTP.get_response(URI.parse(url))
        data = resp.body
        result = JSON.parse(data)
        next if result["cls1"] == nil
        a =  result["cls1"].sort {|a,b| b[1] <=> a[1]}
        type = a[0][0]
        f.write("#{x[0]} <http://dbpedia.org/property/subject> <http://type.org/#{type}> ." )
        f.write("\n" )
      rescue Exception => e
        puts e.message
      end

    }
  }
end

freebase_checkmissing
# freebase_crawler2