require 'matrix'
require 'hungarian.rb'
require "extension_module.rb"

def assingment(a,b)
  solver = Hungarian.new
  data= build_matrix(a,b)
  solution = solver.solve(normalize_matrix(data[2]))
  solution.each{|x|puts data[0][x[0]].to_s + " = " + data[1][x[1]].to_s }
end

def build_matrix(a, b)
  a= preparedata(a)
  b= preparedata(b)
   # m = syntax(a,b) #+  semantic(pt,ps) + value(pt,ps) + entropy(pt,ps)
  m =   entropy_based(a,b)
end
def preparedata(a)
  a.delete_if {|s,p,o| o.instance_of?(RDFS::Resource) }
  return a
end
def syntax(a,b)
  ps=select_predicates(a)
  pt=select_predicates(b)
  m = ps.map{|x|
    pt.map{|y|
      1 - x.jarowinkler_similar(y)
    }
  }
  # puts m
  return [ps,pt,m]
end



def entropy_based(a,b)
  ea= entropy_computation([a])[1]
  eb= entropy_computation([b])[1]

  va= vocabulary(a)
  vb= vocabulary(b)

  m = ea.keys.map{|x|    
    eb.keys.map{|y|   
       1.0 - ((1.0 - (ea[x] - eb[y]).abs) * object_distance(va[x.to_s],vb[y.to_s]))
    }    
  }
  m.each_index{|idx|
    x=m[idx] 
    min = x.min
    index = x.find_index(min)
    puts "INDEX"
    puts ea.keys[idx]
    puts eb.keys[index]
    }
    
  # puts m
  return  [ea.keys,eb.keys,m]
end

def object_distance(x,y)
  # return    jaccard(x,y)
  # return "". get_similarity(x.join(""),y.join(""),"LEVENSHTEIN")
  
  all = (x + y).uniq.sort
  
  a = all.map{|c| x.grep(c).size }
  b = all.map{|c| y.grep(c).size }
   
  c = cosine(a,b)
  c = 0 if c.nan?
  # puts c
  return c
  
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