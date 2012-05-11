require 'set'
require File.dirname(__FILE__) + "/a_star" 
################################
class AttributeQuery
  attr_reader :attribute_alignment, :threshold, :qtype
  def initialize(attribute_alignment, threshold , type )
    @attribute_alignment=attribute_alignment
    @threshold=threshold
    @qtype=type
  end
end
######################################
class ClassQuery
  attr_reader :attribute, :value
  def initialize(attribute, value)
    @attribute=attribute
    @value=value
  end
end
##########################################
class TransitionQuery
   attr_reader :qa,:qc, :weight
  def initialize (qa,qc,weigth=0)
    @weight=weigth
    @qa =qa
    @qc =qc
  end
  def qtype()
    @qa.qtype
  end
  def == (t)
    self == t
  end
  def query (instance)
    puts "QUERY TRANSITION COST FOR:" + instance
    CandidateSet.new(self,instance)
  end 
  def penalize ()
    @weight  = @weight + 1
  end
  def unpenalize ()
    @weight  = @weight - 1
  end
  
  def to_s()
     if qc != nil
       qa.attribute_alignment.to_s + " " + qa.threshold.to_s + " " + qtype.to_s + " AND " + qc.attribute + " " + qc.value + " " + @weight.to_s
     else
       qa.attribute_alignment.to_s + " " + qa.threshold.to_s + " " + qtype.to_s + " " + @weight.to_s
     end
  end
end
##################################################
class Node < AStarNode   
   attr_reader :name,:transition, :instance,:solver,:candidate,:nodecost
   attr_accessor :number
   alias_method :inspect, :name
   @@instances=nil
   @@transitions=nil
   @@solver=nil
    
    
  def initialize(source_instance,transition) 
   @number=0 
   @nodecost=0
    @instance=source_instance
    @transition=transition
    @neighbours=[]
    @name = "NODE " +source_instance  + " - " + transition.to_s
    
  end
  def connect(node)
    @neighbours << node
  end
  def guess_distance(other) 
    1
  end
  def neighbors
     puts "Getting Neigbout for " + to_s
    # if @neighbours.size == 0
    node_expander()       
    # end
    # puts @neighbours.size
    # puts @neighbours   
    @neighbours
  end
  def cost()
    return @nodecost if @nodecost != 0
    puts "CURRENT TRANSITION: " 
    puts transition.to_s
    @candidate= transition.query(instance)
    @nodecost  = @candidate.elements.size
     puts @nodecost
    if @nodecost == 0
    @nodecost  = Node::MAX_COST
      transition.penalize()
    else
     transition.unpenalize()
    end     
    return @nodecost
  end 
  def movement_cost(node)    
     puts "MOVEMENT COST" 
     return 1 if node == Node.goal()
     cost= node.cost() 
     puts "COST COMPUTED"
     puts cost     
     cost
  end  
   def node_expander()     
     puts "NODE COST: " + @nodecost.to_s
      puts "POP"
    if @@instances.size == 0        
       puts "GOAL"
       self.connect(Node.goal)
      return
    end
    rank_transitions() 
    # remove_transitions()
    update_transitions() if $transitionupdate
    source_instance = @@instances.pop   
    puts source_instance
    puts @@transitions 
    @@transitions.each{|transition|
      neighbour = Node.new(source_instance, transition)      
      neighbour.number=@number+1       
      self.connect(neighbour)     
    }   
   
end
def update_transitions()
  puts "LOCAL PATH " + self.name
       path = local_path() 
       return if path == nil 
        # puts path
         # path.each{|x| 
         # puts x 
         # puts x.candidate}
        puts "END" 
       return if path.size != 3
        puts "SOLVING ... " 
        data = path.map{|x| x.candidate.elements}
    solution  = @@solver.solve(data,path.map{|x| x.instance})
    qc =  @@solver.class_queries(solution,data, EuclidianClassSolver.new)
    newtransitions=[]
     
    @@transitions.delete_if{|x| x.qc != nil} if qc.size > 0
    qc.uniq.each{|q|
    @@transitions.each{|t|
     newtransitions << TransitionQuery.new(t.qa,q,t.weight-1)
      }        
      }
    @@transitions = newtransitions + @@transitions   
    puts "TRANSITIONS UPDATED"
    puts @@transitions
end
 def rank_transitions()
      @@transitions.sort!{|a,b| a.weight <=> b.weight}
    end
 def remove_transitions()
      @@transitions.delete_if{|a | a.weight > 0}
    end
def to_s
  @number.to_s + " - " + @name
end 

   def Node.instances=(instances)
     @@instances = instances
   end
   def Node.transitions=(transitions)
     @@transitions = transitions
   end
   def Node.solver=(solver)
     @@solver = solver
   end
end
class HeuristicSearch   
  def initialize(instances,alignments,solver)
    puts ""
     puts "###########################################################################"
    puts "######################## START SEARCH ###########################"
    puts "###########################################################################"
     
  
    Node.solver=solver 
    Node.instances=instances   
    Node.transitions=transitions(alignments)
   
    
  end
  def search()   
    start = Node.new("start",1)    
    cost, path = start.path_to(Node.new("Goal",1))
    
puts "Total Cost: #{cost}"
puts "Path: #{path.collect {|node| node.name}.join(', ')}"
print "\n"
path.delete(path.first)
path.delete(path.last)
return path
  end
  def transitions(alignments)
    xtransitions =[]
    alignments.each{|alignment| 
      xtransitions <<  TransitionQuery.new(AttributeQuery.new(alignment,0.6,QueryType::EXACT),nil)
      xtransitions <<  TransitionQuery.new(AttributeQuery.new(alignment,0.6,QueryType::BIF),nil)
      xtransitions <<  TransitionQuery.new(AttributeQuery.new(alignment,0.6,QueryType::AND),nil)
      xtransitions <<  TransitionQuery.new(AttributeQuery.new(alignment,0.6,QueryType::OR),nil)             
      }     
      xtransitions
  end
end

# HeuristicSearch.new (["A","B"],[44,77]).search()

 # puts TransitionQuery.new(AttributeQuery.new("alignment",0.6,QueryType::EXACT),"q", 1)#==  TransitionQuery.new("t.qa","q", 1)