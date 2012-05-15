
require 'matrix'
require  File.dirname(__FILE__) +'/../heuristicsearch/heuristicsearch.rb'
require  File.dirname(__FILE__) +'/hungarian.rb'
require  File.dirname(__FILE__)+ "/../util/extension_module.rb"
 
################################
class AttributeAlignment
  attr_reader :source,:target
  def initialize (a,b)
    @source=a
    @target=b
  end
  def to_s
    "[#{@source}=#{@target}]"
  end
end
class NoAligner
  include Serimi_Module
def alignment_algorithm(instances,limit)
     entitylabels = source_entity_labels(instances[0..limit]).uniq
     entitylabels.map{|a| AttributeAlignment.new (a,"?p")}
end
end

############################
class SerimiAligner
  include Serimi_Module
def alignment_algorithm(instances,limit)
     sourcedata =[]
     targetdata =[]
      
      entitylabels = source_entity_labels(instances[0..limit]).uniq
      
      count = limit # used to force the selection of at least "limit" target instances.
      instances.each {|s|
         
        break if count <= 0
        tmp =  Query.new.adapters($session[:origin]).sparql("select ?p ?o where {  #{s.to_s} ?p ?o }").execute
        tmp.each {|p,o| sourcedata << [s,p,o] }        
        entitylabels.each{|pre|
        tmp = TransitionQuery.new(AttributeQuery.new(AttributeAlignment.new(pre,"?p"),0.6,QueryType::BIF),nil).query(s).elements
        count = count - 1 if tmp.size > 0
        
        targetdata = targetdata + tmp  
         }
      }
       
      targetdata.uniq!  
      puts " TARGET SIZE " + targetdata.size.to_s 
      entitylabels.map!{|x,y| x.to_s}
      puts "BEFORE ALIGNMENT SOURCE ENTITY LABELS "
      puts entitylabels
      puts "#####################################"
      alignments = assingment(sourcedata,targetdata)
      puts "ALIGNMENT "
      puts alignments
      alignments.delete_if{|x| !entitylabels.include?(x.source)}
      alignments.delete_if{|x| x.target == ""}
      alignments
end

def assingment(a,b)
  solver = Hungarian.new
  data= build_matrix(a,b)
  solution = solver.solve(data[2])
  solution = solution.map{|x| AttributeAlignment.new (data[0][x[0]].to_s, data[1][x[1]].to_s) }
  puts "SORUCE PREDICATES"
  puts data[0]
  puts "TARGET PREDICATES"
  puts data[1]
  return solution
end

def build_matrix(a, b)
  a= preparedata(a)
  b= preparedata(b)
   # m = syntax(a,b) #+  semantic(pt,ps) + value(pt,ps) + entropy(pt,ps)
  m =   entropy_based(a,b) 
  m2 =  syntax(a,b)
  
  # puts "AAAA"
  # puts m[1]
  # puts "XXXXXX"
  # puts m2[1]
  
   m[2] = sum_arrays_normalizing(m[2],m2[2])
  
  return m
   
end
def preparedata(a)
  a.delete_if {|s,p,o| o.instance_of?(RDFS::Resource) }
  return a
end
def syntax(a,b)
  ps=select_predicates(a).sort
  pt=select_predicates(b).sort
   
  m = ps.map{|x|
    pt.map{|y|
      1 - x.jarowinkler_similar(y)
    }
  }
  # puts m
  return [ps,pt,normalize_matrix(m)]
end
 
def entropy_based(a,b)
  ea= entropy_computation([a])[1]
  eb= entropy_computation([b])[1]
  
  # puts "TARGET ENTRO"
  # puts b

  va= vocabulary(a)
  vb= vocabulary(b)

  m = ea.keys.sort.map{|x|    
    eb.keys.sort.map{|y|   
       1.0 - ((1.0 - (ea[x] - eb[y]).abs) * object_distance(va[x.to_s],vb[y.to_s]))
    }    
  }
  # m.each_index{|idx|
    # x=m[idx] 
    # min = x.min
    # index = x.find_index(min)
    # puts "INDEX"
    # puts ea.keys[idx]
    # puts eb.keys[index]
    # }
    
  # puts m
  return  [ea.keys.sort,eb.keys.sort,normalize_matrix(m)]
end

def object_distance(x,y)
  return    jaccard(x,y)
  # return "". get_similarity(x.join(""),y.join(""),"LEVENSHTEIN")
  
  all = (x + y).uniq.sort
  
  a = all.map{|c| x.grep(c).size }
  b = all.map{|c| y.grep(c).size }
   
  c = cosine(a,b)
  c = 0 if c.nan?
  # puts c
  return c
  
end
def sum_arrays_normalizing *a
    
  arr = []
  a[0].each_index do |r|       # iterate through rows
    row = []
    a[0][r].each_index do |c|  # iterate through columns
      # get sum at these co-ordinates, and add to new row
      row << a.inject(0) { |sum,e| sum += e[r][c] }.to_f / a.size.to_f
    end
    arr << row  # add this row to new array
  end
  # puts arr
  arr # return new array
end
def normalize_matrix(matrix)
  max = [matrix[0].size,matrix.size].max-1
  #Normalizing matrix
  m=Array.new(max)
  for i in 0..max
    m[i]=Array.new(max)
    for j in 0..max
      if matrix[i]==nil || matrix[i][j]==nil
      m[i][j]=1.0
      else
      m[i][j]=matrix[i][j]
      end
    end
  end
  return m
end
def  vocabulary(a)
  va = Hash.new
  pa = select_predicates(a)

  pa.each{|x|
    o = select_object_vocabulary(a,x)
    va[x]=o
  }
  return va
end

def select_predicates(instances)
  pre = instances.map{|s,p,o| p.to_s}.uniq
  return pre
end

def select_object_vocabulary(instances,pre)
  return instances.map{|s,p,o| o.to_s.downcase.split("") if p.to_s == pre.to_s}.compact.flatten
end

def cosine(a,b) 
  c =  a.uniq.map{|x| a.find_all{|s| s==x}.size} 
  d= a.uniq.map{|x| b.find_all{|s| s==x}.size} 
  prod=0
  c=a
  d=b
  c.each_index{|i| prod = prod + c[i]*d[i]} 
  d1 =  (c.map{|i| i*i}.inject {|sum, n| sum + n })
  d2 = (d.map{|i| i*i}.inject {|sum, n| sum + n })
  
  prod.to_f / Math.sqrt(d1 * d2)
end  
 # puts "x".get_similarity("xaaa","xaaa","LEVENSHTEIN")
end

class KMeansAligner < SerimiAligner
  include Serimi_Module
def alignment_algorithm(instances,limit)
     sourcedata =[]
     targetdata =[]
      
      entitylabels = source_entity_labels(instances[0..limit]).uniq
      
      count = limit # used to force the selection of at least "limit" target instances.
      instances.each {|s|
         
        break if count <= 0
        tmp =  Query.new.adapters($session[:origin]).sparql("select ?p ?o where {  #{s.to_s} ?p ?o }").execute
        tmp.each {|p,o| sourcedata << [s,p,o] }        
        entitylabels.each{|pre|
        tmp = TransitionQuery.new(AttributeQuery.new(AttributeAlignment.new(pre,"?p"),0.6,QueryType::BIF),nil).query(s).elements
        count = count - 1 if tmp.size > 0
        
        targetdata = targetdata + tmp  
         }
      }
       
      targetdata.uniq!  
      puts " TARGET SIZE " + targetdata.size.to_s 
      entitylabels.map!{|x,y| x.to_s}
      puts "BEFORE ALIGNMENT SOURCE ENTITY LABELS "
      puts entitylabels
      puts "#####################################"
      alignments = assingment(sourcedata,targetdata) 
      alignments.delete_if{|x| !entitylabels.include?(x.source)}
      alignments.delete_if{|x| x.target == ""}
      alignments
end
def assingment(a,b)
  a= preparedata(a)
  b= preparedata(b)
  alignment = []
  d1 =  entropy_based(a,b) 
  d2 =  syntax(a,b)
  
  m1 = d1[2]
  m2 = d2[2]
  
  data=[]
  
  rows = d1[0].size - 1
  cols = d1[1].size - 1
  
  puts rows
  puts cols
  indexes = Hash.new
  min=1
  min_index=0
  for i in 0..rows
    for j in 0..cols
        data << [m1[i][j],m2[i][j]]
        if min > m1[i][j]+m2[i][j]
          min=m1[i][j]+m2[i][j]
          min_index=data.size-1     
        end
        indexes[data.size-1]=[i,j]
      end
  end   
  puts data.map{|x| x.join(" ") }
  require 'k_means' 
   
  centroids = 2 #d1[0].size 
  puts "CENTROIDS"
  puts centroids 
  # kmeans = KMeans.new(data, :centroids => centroids)
  kmeans = KMeans.new(data, :custom_centroids => [CustomCentroid.new([0,0]),CustomCentroid.new([1,1])])
  puts kmeans.inspect   # Use kmeans.view to get hold of the un-inspected array
  kmeans.view.each{|x|
    if x.include?(min_index)
    x.each{|y|
      alignment << AttributeAlignment.new (d1[0][indexes[y][0]].to_s, d1[1][indexes[y][1]] .to_s)
      puts y
      puts d1[0][indexes[y][0]] 
      puts d1[1][indexes[y][1]] 
    } 
    end
    } 
    # puts "ALIGNMENT"
    # puts alignment
  return alignment.compact
end
end
class CustomCentroid
  attr_accessor :position
  def initialize(position); @position = position; end
  def reposition(nodes, centroid_positions); end
end

