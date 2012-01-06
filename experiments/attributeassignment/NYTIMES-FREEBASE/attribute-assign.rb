require 'matrix'
require 'hungarian.rb'
require "extension_module.rb"



def assingment(a,b)
  solver = Hungarian.new
  data= build_matrix(a,b)
  solution = solver.solve(data[2])
  solution.each{|x|puts data[0][x[0]].to_s + " = " + data[1][x[1]].to_s }
end

def build_matrix(a, b)

  ps=select_predicates(a)
  pt=select_predicates(b)

  m = syntax(ps,pt) #+  semantic(pt,ps) + value(pt,ps) + entropy(pt,ps)
  [ps,pt,m]
end

def syntax(a,b)
  
  m = a.map{|x|
     b.map{|y|
          1 - x.jarowinkler_similar(y)
       }
     } 
  # puts m
  return m
end

def select_predicates(instances)

  pre = instances.map{|s,p,o| p.to_s}.uniq
  puts "#####"
  puts pre

  return pre
end

