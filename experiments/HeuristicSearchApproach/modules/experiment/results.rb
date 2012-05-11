def check_result()
  puts "CHECKING RESULTS"
  #    [:drugbank ,    :dbpedia ,    :stitch ,    :tcm ,    :sider ,    :linkedct ,    :bio2rdf ,    :diseasome,     :dailymed ,    :yago ]
  #    linesbygroup = []
  solution=[]
  encountered=[]
  subjects=[]
  recall=[]
  precision=[]

  File.open("#{$current_dir}/../reference/reference.txt", 'r').each { |line|
    solution << line.rstrip

  }
  solution.uniq!

  File.open( $output.path, 'r').each { |line|
    encountered << line.rstrip
  }
  encountered.uniq!
  File.open( $log_subjects.path, 'r').each { |line|
    subjects << line.rstrip
  }
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
  solution.delete_if{|x| !subjects.include?(x.split("=")[0]) } if $globalrecall == nil

  solution.uniq!
  encountered.uniq!

  puts solution.sort
  puts "$$$$$$"
  puts encountered.sort

  puts "######## DIFFERENCE  encountered - solution"

  puts  encountered - solution

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

  puts "RECALL: " + recall.to_s
  puts "PRECISON: " + precision.to_s
  puts "FMEASURE: " + fmeasure.to_s
  return [fmeasure,recall, precision]
end
