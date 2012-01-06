def check_result()

  #    [:drugbank ,    :dbpedia ,    :stitch ,    :tcm ,    :sider ,    :linkedct ,    :bio2rdf ,    :diseasome,     :dailymed ,    :yago ]
  #    linesbygroup = []
  solution=[]
  encountered=[]
  subjects=[]
  recall=[]
  precision=[]

  File.open("./reference/reference.txt", 'r').each { |line|
    solution << line
  }

  File.open( $output.path, 'r').each { |line|
    encountered << line
  }

  File.open( $log_subjects.path, 'r').each { |line|
    subjects << line.rstrip
  }

 
  puts "NOT FOUND"
  puts subjects.uniq.size
  puts encountered.uniq.size

  golden = solution.map{|x| x.split("=")[0]}
  encountered.delete_if{|x| !golden.include?(x.split("=")[0]) }
  solution.delete_if{|x| !subjects.include?(x.split("=")[0]) }

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
