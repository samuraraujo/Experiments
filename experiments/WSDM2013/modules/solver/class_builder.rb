#Serimi Functionalities.
#Author: Samur Araujo
#Date: 10 March 2012
#License: SERIMI is distributed under the LGPL[http://www.gnu.org/licenses/lgpl.html] license.
require  File.dirname(__FILE__)+'/./solver.rb'
class SimpleClassSolver < ClassSolver
  def solve(positive,negative)
    classqueries=[]
    criterias =  frequent_predicates( positives.map{|s,p,o| [p,o]} - negatives.map{|s,p,o| [p,o]})

    criterias[0..4].each {|criteria|
      classqueries << ClassQuery.new(criteria[0][0],criteria[0][1])
    }
    return classqueries
  end 
  def frequent_predicates(triples)
    triples.map!{|p,o| [p.to_s,o.to_s]}
    #computes the frequency of the predicate/value pair and select the 3 mostfrequency to build the class queries.
    freq = triples.inject(Hash.new(0)) { |h,v| h[v] += 1; h } #computes the frequency
    freq =  freq.sort {|a,b| b[1]<=>a[1]} # select a the most frequent
  end
end 
class EuclidianClassSolver < ClassSolver
  def solve(positive,negative)
    puts "EUCLIDIAN SOLVER"

    classqueries=[]
    pf = frequent_predicates( positive.map{|s,p,o| [p,o]} )
    nf = frequent_predicates( negative.map{|s,p,o| [p,o]} )

    pf = Hash[pf]
    nf = Hash[nf]

    pf.delete_if {|key, value| value == 1 }

    pf.keys.each{|x|
      n = nf[x]
      n = 0 if n == nil
      
      pf[x] = pf[x]^2 - n^2
    }
    
    puts pf.size
    puts nf.size
    puts "SELECTED PREDICATES / VALUE"

    pf.sort {|a,b| b[1]<=>a[1]}[0..4].each {|criteria|
      puts criteria
      classqueries << ClassQuery.new(criteria[0][0],criteria[0][1])
    }
   
    return classqueries
  end

  def frequent_predicates(triples)
    triples.map!{|p,o| [p.to_s,o.to_s]}
    #computes the frequency of the predicate/value pair and select the 3 mostfrequency to build the class queries.
    freq = triples.inject(Hash.new(0)) { |h,v| h[v] += 1; h } #computes the frequency
    freq =  freq.sort {|a,b| b[1]<=>a[1]} # select a the most frequent
  end
end
######################################################
class OptimalClassSolver < ClassSolver
  include Serimi_Module
  def solve(positive,negative)
    puts "OptimalClassSolver SOLVER"
    max_coverage_keys=[]
     classqueries=[]
     perkey = Hash.new 
     
     return [] if negative.size == 0 # there is not need of class queries in this case
    
    
     positive = positive.uniq.map{|s,p,o| [getCode(s.to_s.hash.abs),p.to_s,o.to_s ]  }.compact
     negative = negative.uniq.map{|s,p,o| [getCode(s.to_s.hash.abs),p.to_s,o.to_s ]  }.compact
     
     all = positive + negative
     all.uniq!
     
     all.map{|s,p,o| [p,o]}.uniq.each{|p,o| perkey[[p,o]] = [ ] }
     all.each{|s,p,o| perkey[[p,o]] << s } 
     
     positive = positive.map{|s,p,o| s}.uniq
     negative = negative.map{|s,p,o| s}.uniq
     return [] if positive.size < 5
     puts "POSITIVES"
      puts positive
    begin
    key = cluster(positive, negative, perkey) 
    break if key == nil 
    
    puts "REMOVE POSITVE FOR KEY"
    
    key.each{|x|
      
     max_coverage_keys  << x if  perkey[x].uniq.size > 5
      puts x
      puts "POSITIVE SIZE"
      puts positive.size
         
      puts "KEYSIZE SIZE"
      puts perkey[x].uniq.size
      puts perkey[x].uniq
     
    positive = positive - perkey[x] 
    perkey.delete(x)
    puts "DIFFERENCE SIZE"
    puts positive.size  
      }
    
    end while(key != nil and positive.size > 0)
      # exit
    max_coverage_keys.compact!  
    puts "SELECTED PREDICATES / VALUE"

    max_coverage_keys.each {|criteria|  
      
      classqueries << ClassQuery.new(criteria[0],criteria[1])
    }
      
    return classqueries
  end
  def cluster(positives, negatives, perkey)
    keys = perkey.keys.uniq
    
    found = [] 
    data=[] 
    hash = Hash.new
   
    keys.each{|x|
      a = perkey[x]
      
      values = [1.0 - jaccard(a, positives), (a & negatives).size.to_f / negatives.size.to_f]
      puts x
      puts values 
        data << values
        hash[values] =[] if hash[values]  == nil
        hash[values] << x 
      } 
    data << [0.0,0.0]
    data << [0.0,1.0]
    data << [1.0,0.0]
    data << [1.0,1.0] 
    data.uniq! 
    return findBestKey(data,hash)
    
end
def findBestKey(data,hash)
    data_set = Ai4r::Data::DataSet.new(:data_items=>data)
    centroidlinkage = Ai4r::Clusterers::CentroidLinkage.new.build(data_set,4).clusters
    puts "checking points"
    count=0
    centroidlinkage.each{|z|
      puts "######### cluster"
      puts count+=1
      puts z.data_items.sort.map{|x| x.join(", ")}
    }
    puts "LIST PAIRS"
    centroidlinkage.each{|x|
      if x.data_items.include?([0.0,0.0]) 
        x.data_items.sort{|a,b| a[0] <=> b[0]  }.each{|point|
          # x.data_items.each{|point|  
          puts "found"
          puts point
          puts hash[point] 
          return  hash[point]   if hash[point]  != nil  
        }
      end
    }  
    return nil 
  end
end
 