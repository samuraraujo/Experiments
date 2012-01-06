# ruby serimi.rb -s imdb -t dbpedia -c http://data.linkedmdb.org/resource/movie/film -f nt
require 'serimi_class'
require './results.rb'

##################### SET THE PARAMETER FOR THIS EXPERIMENT #################
@options = {"verbose".to_sym => false,
"logfile".to_sym => nil ,
"source".to_sym => "nytimes",
# "target".to_sym => "dbpedia_local",
"target".to_sym => "dbpedia",
  # "class".to_sym => "http://data.linkedmdb.org/resource/movie/film",
:class=>" <http://data.nytimes.com/elements/nytd_geo> ",
"append".to_sym => "a",
"format".to_sym => "txt",
"chunk".to_sym => 10,
"topk".to_sym => 1,
"offset".to_sym => 0,
"stringthreshold".to_sym => 0.7,
"usepivot".to_sym => 'true',
"blocking".to_sym => 'true' ,
}

def experiment(orderby, predicate)
  $experiment=true
  $orderby=nil
  $shuffle=false
  
  $orderbyclause=" ?s <#{predicate}> ?oo . }  " if predicate != nil
  $orderby=" order by ?oo " if orderby

  puts "EXPERIMENT"
  $shuffle=!orderby
  puts "$shuffle"
  puts $shuffle
  puts "$orderbyclause"
  puts $orderbyclause
  puts "$orderby"
  puts $orderby

  Serimi.new(@options)
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
  File.open("./reference/reference.txt", 'r').each { |line|
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
# predicate="http://data.linkedmdb.org/resource/movie/runtime"
experiment(false,predicate) 
# 