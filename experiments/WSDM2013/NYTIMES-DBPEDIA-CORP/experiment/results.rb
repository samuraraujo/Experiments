def fmeasure(a,b)
  return 0.0 if a == 0 || b == 0
  2.0 * (a * b)  / (a+b)
end
def check_result()
  puts "CHECKING RESULTS"
  #    [:drugbank ,    :dbpedia ,    :stitch ,    :tcm ,    :sider ,    :linkedct ,    :bio2rdf ,    :diseasome,     :dailymed ,    :yago ]
  #    linesbygroup = []
  solution=[]
  encountered=[]
  subjects=[]
  recall=[]
  precision=[]
  candidates=[]
  label = "Fri Jul 20 12:29:55"
  File.open("/Users/samuraraujo/Documents/workspace2/ManyExperiments/experiments/HeuristicSearchApproach/NYTIMES-DBPEDIA-CORP/reference/reference.txt", 'r').each { |line|
    solution << line.rstrip
  }
  solution.uniq!
  dbpedia = solution[0].index("dbpedia") != nil
  # dbpedia =false
  init_dic if dbpedia
  solution = dbpedia_post(solution) if dbpedia

  File.open( "/Users/samuraraujo/Documents/workspace2/ManyExperiments/experiments/HeuristicSearchApproach/NYTIMES-DBPEDIA-CORP/output/#{label} +0200 2012_mappings.txt", 'r').each { |line|
    encountered << line.rstrip

  }
  encountered.uniq!
  encountered = dbpedia_post(encountered) if dbpedia

  File.open(  "/Users/samuraraujo/Documents/workspace2/ManyExperiments/experiments/HeuristicSearchApproach/NYTIMES-DBPEDIA-CORP/output/#{label} +0200 2012_subjects.txt", 'r').each { |line|
    subjects << line.rstrip
  }
   

  File.open( "/Users/samuraraujo/Documents/workspace2/ManyExperiments/experiments/HeuristicSearchApproach/NYTIMES-DBPEDIA-CORP/output/#{label} +0200 2012_candidates.txt", 'r').each { |line|
    candidates << line.rstrip
  }
  candidates = dbpedia_post(candidates) if dbpedia
  subjects.uniq!
  puts "SUBJECTS"
  $number_subjects = subjects.uniq.size
  puts $number_subjects
  puts "SUBJECTS FOUND"
  puts encountered.uniq.size
  
  if $inverted
    solution.map!{|x|
      y = x.split("=")
      y[1] +"=" +y[0]
    }
  end

  golden = solution.map{|x| x.split("=")[0]}
  encountered.delete_if{|x| !golden.include?(x.split("=")[0]) }
   solution.delete_if{|x| !subjects.include?(x.split("=")[0]) } #if $globalrecall == nil

  solution.uniq!
  encountered.uniq!

  # puts solution.sort
  puts "$$$$$$"
  # puts encountered.sort

  puts "######## DIFFERENCE  encountered - solution"

  # puts  encountered - solution

  puts "######## DIFFERENCE  solution - encountered"
  puts (solution - encountered)[0..10]

  positive = 0
  false_positive = 0
  negative = 0
  false_negative = 0
  positive = (solution & encountered).size.to_f
  false_positive = (encountered - solution).size.to_f
  false_negative = (solution - encountered).size.to_f

  puts positive
  puts  false_positive
  puts  false_negative

  precision =(positive.to_f / (positive.to_f + false_positive.to_f))

  recall = (positive.to_f / (positive.to_f + false_negative.to_f))

  fmeasure = fmeasure(recall,precision)#.round(3)

  paircompleteness = (candidates & solution).size.to_f / solution.size.to_f

  puts "PAIRCOMPLETENESS: " + recall.to_s
  puts "RECALL: " + recall.to_s
  puts "PRECISON: " + precision.to_s
  puts "FMEASURE: " + fmeasure.to_s
  return [fmeasure,recall, precision,paircompleteness]
end

def summary()
  ww "Parameters:"
  @options.each { |k,v| ww "#{k} => #{v}" }

  ww "$shuffle"
  ww $shuffle
  ww "$orderbyclause"
  ww $orderbyclause
  ww "$orderby"
  ww $orderby

  rr =  ($number_subjects.to_f / $number_homonyms.to_f)
  pc= $xresults[3]
  f1= 2* rr*pc / (rr+pc)

  ww " & #{$name}  & #{XNode.transitions.size} & #{( ($featurecounter.positive_queries +  $featurecounter.negative_queries) / $limit.to_f ).to_f.precision(2).to_s}   & #{($totallearningtime).to_f.precision(2).to_s}  & #{($totalsearchtime).to_f.precision(2).to_s} & #{(100*rr).to_f.precision(2).to_s} & #{(100*pc).to_f.precision(2).to_s} & #{(100*f1).to_f.precision(2).to_s}  \\\\ "
  ww "LEARNING TIME: " + $totallearningtime.to_s
  ww "SEARCH TIME: " + $totalsearchtime.to_s
  ww "MATCHER TIME: " + $matchertotaltime .to_s
  ww "TOTAL TIME: " +  ($totallearningtime+$totalsearchtime+$matchertotaltime).to_f.precision(2).to_s
  ww "PAIR COMPLETENESS: " + $xresults[3].to_s
  ww "RECALL: " + $xresults[1].to_s
  ww "PRECISON: " + $xresults[2].to_s
  ww "FMEASURE: " + $xresults[0].to_s
  ww "FOUND INSTANCES: " +  $number_subjects.to_s
  ww "NUMBER QUERIES: " +  ($featurecounter.positive_queries +  $featurecounter.negative_queries).to_s
  ww "RATIO NUMBER QUERIES / INSTANCES: " + ( ($featurecounter.positive_queries +  $featurecounter.negative_queries) / $limit.to_f ).to_s

  ww "RATIO QUERIES/POSITIVES: " +  ( $featurecounter.positive_queries.to_f / ($featurecounter.positive_queries +  $featurecounter.negative_queries).to_f ).to_s
  ww "RATIO QUERIES/NEGATIVES: " +  ( $featurecounter.negative_queries.to_f / ($featurecounter.positive_queries +  $featurecounter.negative_queries).to_f).to_s
  ww "NUMBER HOMONYMS: " +  $number_homonyms.to_s
  ww "RATIO HOMONYMS/INSTANCES: " + ($number_homonyms.to_f / $number_subjects.to_f).to_s
  ww "INSTANCES / HOMONYMS RATIO: " + ( $number_subjects.to_f/$number_homonyms.to_f).to_s
  ww "SORTED LIST OF HOMONYMS: " +  $list_number_homonyms.sort.join("\t")
  ww "LIST OF HOMONYMS: " +  $list_number_homonyms.join("\t")
  ww "ELAPSED TIME S: " +  (Time.now() - $t1).to_s
  ww "ELAPSED TIME M: " +  ((Time.now() - $t1) / 60).to_s

# $distribution.each_index{|x|
#
# begin
# puts cosine($distribution[x],$distribution[x+1])
# rescue
# end
# }
end

def init_dic()
  $dic = Hash.new if $dic == nil
  File.open("../reference/dic.txt", 'r').each { |line|
    line = line.rstrip.split("=")
    $dic[line[0]]=line[1]
  }
end

def save_dic()
  f = File.open("../reference/dic.txt", 'w')
  $dic.each{|k,v|
    f.write(k+ "=" +v + "\n")
  }
  f.fsync
  f.close
end

def dbpedia_post(data)
  newdata = []
  t = []
  count=0
  finished = []

  data.each{|line|
      c = line.split("=")
        sleep(0.3) if $dic[c[1]] == nil
    t <<  Thread.new{
      count+=1
      a = count
      puts count
      finished << a
      if line.index("yago") != nil
      newdata <<    line
      next
      end

      y = line.split("=")
      link = dbpedia_deref(y[1], 1)
      $dic[y[1]]=link if link.index("/resource/") == nil
      newdata <<  y[0] +"=" + link

      finished.delete(a)
      puts "END " + a.to_s
    }
    
     
     
  }
  t.map{|x|x.join}
  save_dic()
  return newdata
end

def dbpedia_deref(link, count)

  return link if count > 5
  if $dic!= nil && $dic[link] !=  nil
    return $dic[link]
  end
  
  uri = URI(link)
 
  res = Net::HTTP.get_response(uri)
  puts  "Resopnse: " + res.code
  puts res['location']
  if res.code == '303' || res.code == '301'
    return dbpedia_deref(res['location'], count + 1)
  else
  link
  end
end

def run_full_evaluation()
  predicate = nil
  # predicate="http://www.w3.org/2003/01/geo/wgs84_pos#long"
  p "SondaA EVALUATION"
  @options["name".to_sym]='SondaA'
  experiment(false,predicate)
  # exit
  p "SondaC EVALUATION"
  @options["name".to_sym]='SondaC'
  @options["transitionupdate".to_sym]='true'
  experiment(false,predicate)

  ##########################################
  @options["transitionupdate".to_sym]='false'
  p "SBase SONG EVALUATION"
  @options["searcher".to_sym]='Baseline'
  @options["name".to_sym]='S-based'
  @options["aligner".to_sym]='HierarchicalClusterAligner'
  experiment(false,predicate)

  p "BASELINE EVALUATION"
  @options["aligner".to_sym]='NoAligner'
  @options["name".to_sym]='S-agnostic'
  experiment(false,predicate)
end
 require 'net/http'
  
check_result()
 

# puts dbpedia_deref("http://dbpedia.org/resource/Jabil_Circuit_Incorporated" ,1)
