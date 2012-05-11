# ruby serimi.rb -s imdb -t dbpedia -c http://data.linkedmdb.org/resource/movie/film -f nt
$current_dir = File.dirname(__FILE__)
require  File.dirname(__FILE__)+'/../../modules/initializer.rb'
require  File.dirname(__FILE__)+'/../../modules/experiment/results.rb'

##################### SET THE PARAMETER FOR THIS EXPERIMENT #################
@options = {"verbose".to_sym => false,
"logfile".to_sym => nil ,
"source".to_sym => "sider",
# "target".to_sym => "dbpedia_local",
"target".to_sym => "drugbank",
  # "class".to_sym => "http://data.linkedmdb.org/resource/movie/film",
# :class=>"<http://www.okkam.org/ontology_person1.owl#Person>",
# :class=>"<http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugbank/drugs>",
# :class=>"<http://www.geonames.org/ontology#A.PCLI>",
# :class=>" <http://www.geonames.org/ontology#T>. ?s <http://www.w3.org/2003/01/geo/wgs84_pos#lat> '-14.0' ",
:class=>" <http://www4.wiwiss.fu-berlin.de/sider/resource/sider/drugs> ",
# :class=>" <http://www.geonames.org/ontology#H.STM>. ?s ?k <http://sws.geonames.org/3457415/>  ",
 
"append".to_sym => "a",
"format".to_sym => "txt",
"chunk".to_sym => 15,
"topk".to_sym => 1,
"offset".to_sym => 0,
"stringthreshold".to_sym => 0.7,
"usepivot".to_sym => 'true',
"blocking".to_sym => 'true' ,
"transitionupdate".to_sym => 'false',
"globalrecall".to_sym => 'true',
}

def experiment(orderby, predicate)
  $experiment=true
  $number_homonyms=0
  $list_number_homonyms=[]
  $orderby=nil
  $shuffle=false
  t1 = Time.now()
  $orderbyclause=" ?s <#{predicate}> ?oo . }  " if predicate != nil
  $orderby=" order by ?oo " if orderby

 
  $shuffle=!orderby
 

  Initializer.new(@options)
  puts "RESULTS"
  results = check_result()

  ww "Parameters:"
  @options.each { |k,v| ww "#{k} => #{v}" }
  
  ww "$shuffle"
  ww $shuffle
  ww "$orderbyclause"
  ww $orderbyclause
  ww "$orderby"
  ww $orderby
  ww "RECALL: " + results[1].to_s
  ww "PRECISON: " + results[2].to_s
  ww "FMEASURE: " + results[0].to_s
  ww "NUMBER HOMONYMS: " +  $number_homonyms.to_s
  ww "SORTED LIST OF HOMONYMS: " +  $list_number_homonyms.sort.join("\t")
  ww "LIST OF HOMONYMS: " +  $list_number_homonyms.join("\t")
  ww "ELAPSED TIME: " +  (Time.now() - t1).to_s
end

def experiment_instances(instances)
  # $instances = shuffle($instances, $sample_size) if $experiment
  instances = instances.shuffle if $experiment && $shuffle

  ref_sub=reference_subjects()
  ref_sub.map!{|x| "<#{x}>"}

  instances = instances & ref_sub
  return instances
end

def reference_subjects()
  reference_subjects=[]
  File.open("#{$current_dir}/../reference/reference.txt", 'r').each { |line|
    reference_subjects << line.split("=")[0]
  }
  return reference_subjects.uniq
end 
def ww(str)
  if str.instance_of? Array
    str.each{|x|
      $results.write(x.to_s)
      $results.write("\n")
    }
  else
    $results.write(str.to_s)
    $results.write("\n")
  end

end
predicate = nil
# predicate="http://www.w3.org/2003/01/geo/wgs84_pos#long"
experiment(false,predicate)
# experiment(false,predicate) 
# experiment(false,predicate)
 