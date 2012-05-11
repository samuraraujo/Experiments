$endpoints=Hash.new()

$endpoints[:dbpedia] = "http://dbpedia.org/sparql?default-graph-uri=http://dbpedia.org"
$endpoints[:dbpedia_wis] = "http://wisserver.st.ewi.tudelft.nl:8897/sparql?default-graph-uri=http://dbpedia.org"
$endpoints[:dbpedia_local] = "http://localhost:8894/sparql?default-graph-uri=http://dbpedia.org"
$endpoints[:dbpedia_lod] = "http://lod.openlinksw.com/sparql?default-graph-uri=http://dbpedia.org"
$endpoints[:dbpedia_ams] = "http://ec2-50-17-66-55.compute-1.amazonaws.com/sparql?default-graph-uri=http://dbpedia.org"
#$endpoints[:geonames]="http://wisserver.st.ewi.tudelft.nl:8892/sparql?default-graph-uri=http://geonames.org"
$endpoints[:geonames]="http://localhost:8899/sparql?default-graph-uri=http://geonames.org"
$endpoints[:imdb]="http://localhost:8896/sparql?default-graph-uri=http://imdb.org"
$endpoints[:nytimes]="http://localhost:8890/sparql?default-graph-uri=http://nytimes.org"
$endpoints[:freebase]="http://localhost:8895/sparql?default-graph-uri=http://freebase.org"

