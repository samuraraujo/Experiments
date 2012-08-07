require 'rubygems'
require 'ai4r'

include Ai4r::Classifiers
include Ai4r::Data
##################################################
## Explore the transitions until get a 1 element set or all transitions were explored.
## It is used together with a time based transition rank.
class CardinalityBasedTransitionSelectionAlgorithm
  @previous_node=nil
  def initializer()
  end

  def restart()
    @previous_node = nil
  end

  def process(node)
   
    if @previous_node == nil
      @previous_node = node
    return true
    end

    if @previous_node.cost == XNode::MAX_COST
      if @previous_node > node
      return false
      else
        @previous_node = node
      return true
      end
    elsif @previous_node.cost == 1
    return false
    elsif @previous_node.cost > 1 && @previous_node >= node
      @previous_node = node
    return true
    end
    return false
  end
end

##################################################
## Only explore the transition until a set retrieve a non-empty set
class BasicTransitionSelectionAlgorithm
  @previous_node=nil
  def initializer()
  end

  def restart()
    @previous_node == nil
  end

  def process(node)
    if @previous_node == nil
      @previous_node = node
    return true
    end
    if @previous_node.cost == XNode::MAX_COST
      @previous_node = node
    return true
    elsif @previous_node.cost > 1

    return false
    end
  end
end

##################################################
## Execute all
class GreedyTransitionSelectionAlgorithm
  @previous_node=nil
  def initializer()

  end

  def restart()
    @previous_node == nil
  end

  def process(node)
    return true
  end
end

##################################################
class NaiveBayesClassifier
    @@learning=true  
  attr_accessor :previous_node
  def initialize()
    @@learning=true  
    @classifier=nil
    @previous= nil
    @all_previous=[]
    @sample=[]
    @tmp=[]
    @tmpnodes=[]
    @@attributes =   [ "Minimal Previous Cost",  "Current","Sucess"]
  end

  def NaiveBayesClassifier.learning=(value)
    @@learning=value
  end

  def NaiveBayesClassifier.learning()
    @@learning
  end

  #creates an array representing the query data
  #[t1...tn,q,failure]
  def add_sample(a,b)

    row = []
    if a == nil
     
    row << false
    # row << false
    # row << false
    else
      # row <<  a.transition.object_id
      mcost = false
      a.each{|x|
        if (x.nodecost != 0 and x.nodecost != XNode::MAX_COST)
        mcost = true
        end
        }
      row << mcost
    # row << (a.passby ? false : (a.cost == 0))
    # row << (a.passby ? false : (a.cost == 1))
    end
    row << b.transition.object_id
     success = 1
      a.each{|x|
        if x.cost <= b.cost || ((x&b).size == 0 && (x.nodecost != 0 and x.nodecost != XNode::MAX_COST) && (b.nodecost != 0 and b.nodecost != XNode::MAX_COST))
        success = 0
        end
      } if a != nil
    if (a == nil)
      if (b.cost == XNode::MAX_COST )
      row << 0
      else
      row << 1
      end
    else  
    row << success
     
    end
    # puts "ADDING SAMPLE Q2Q"
    # puts  a.transition.qtype if a!=nil
    # puts  b.transition.qtype
    # puts row.join(", ")
    @tmp << row.map{|x| x.to_s}
  end

  #build vector to add in the tree or to predict
  def row_prediction(a,b)
    row = []
    if a == nil 
    row << false
    else
       mcost = false
      a.each{|x|
        if (x.nodecost != 0 and x.nodecost != XNode::MAX_COST)
        mcost = true
        end
        }
      row << mcost
      
    end
    row <<  b.transition.object_id
    return row.map{|x| x.to_s}
  end

  def predict (a,b)
    # return true if b.number < XNode.learningsize
    row = row_prediction(a,b)
    # puts "PREDICT Q2Q"
    # puts row.join(", ")
    if @classifier == nil
      data_set = Ai4r::Data::DataSet.new(:data_items=>@sample, :data_labels=>@@attributes)
      @classifier = Ai4r::Classifiers::NaiveBayes.new.build(data_set)
    end

    decision = @classifier.eval(row) == "1"

    puts "Predicted: #{decision} ...";
    # @@tree.get_probability_map(row).each{|x| puts x.join(", ")}
    return decision
  end

  def restart()
    
    @previous= nil
    @all_previous=nil
    @tmp=[]
    @tmpnodes=[]
  end

  def commit()
    # puts "TRAINING SAMPLE"
    # puts @tmp

    @sample = @sample + @tmp
  end

  def process(node)
    prediction = true

    # if  node.number < XNode.learningsize
    # puts "FLAG"
    # puts @@learning
    if @@learning
      if @all_previous == nil
        @tmpnodes << [nil,node]
      else
        @tmpnodes << [@all_previous.dup,node]
      end
      
      # @all_previous.each{|x|
        # add_sample(x,node)
        # # add_sample(node,x)
        # add_sample(nil,node)
      # }
      
     add_sample(@all_previous,node)
     
    else  
      # puts "PREDICTING"
      prediction = predict(@all_previous,node)
      
    end
    @all_previous =[] if @all_previous == nil
    @all_previous << node
    return prediction
  end

  def test_error()
    next [0,0] if @sample.size == 0
    @classifier = nil

    error = @tmpnodes.map{|x|
      a=x[0]
      b=x[1]
      p = predict(a,b)
      t = false
      if (a == nil)
        if (b.cost == XNode::MAX_COST )
        t= false
        else
        t= true
        end
      else
          t = true
      a.each{|x|
        if x.cost <= b.cost || ((x&b).size == 0 && (x.nodecost != 0 and x.nodecost != XNode::MAX_COST) && (b.nodecost != 0 and b.nodecost != XNode::MAX_COST))
        t = false
        end
      }  
      end
      p == t 
    }
    error.delete_if{|x| x==false}
    return [ error.size , @tmpnodes.size]

  end
end

class DecisionTreeSelectionAlgorithm
  
  def initialize()
    @error=[]
    @predictors = Hash.new
  end

  #create and process one classfier per alignment
  def process(node)
      # puts "PROCESSING NODE"
      
    @predictors["a"] =  NaiveBayesClassifier.new() if @predictors["a"] == nil
    prediction = true
    # puts "################ PROCESSING #############"
    # puts @previous_reduction
    # puts node
    prediction=@predictors["a"].process(node)
    
    return prediction
  end

  def test_error()
    error =0
    size=0
    #compute the average of the error per classifier
    @predictors.values.map{|x| x.test_error}.each{|x|
      error+=x[0]
      size+=x[1]
    }
    # $test_error.write(error.to_f)
    # $test_error.write(", ")
    # $test_error.write(size.to_f)
    # $test_error.write(", ")
    xerror = 1 - (error.to_f/size.to_f)
    @error<< xerror
    $test_error.write(xerror)
    $test_error.write("\n")
    $test_error.fsync
  end

  def commit()
  
    if @error.size > 2*XNode.transitions.size and @error[@error.size-3] == @error[@error.size-2] && @error[@error.size-2] == @error[@error.size-1]
      NaiveBayesClassifier.learning=false
      # puts "TRAINED"
      # puts NaiveBayesClassifier.learning
    else
      test_error()
    end
    @predictors.values.each{|x| x.commit()} if @predictors.size > 0
  end

  def restart()
    @predictors.values.each{|x| x.restart()} if @predictors.size > 0
  end
end

# DATA_LABELS = [ 'city', 'age_range', 'gender', 'marketing_target'  ]
#
# DATA_ITAMS = [
# ['New York',  '<30',      'M', 'Y'],
# ['Chicago',     '<30',      'M', 'Y'],
# ['Chicago',     '<30',      'F', 'Y'],
# ['New York',  '<30',      'M', 'N'],
# ['New York',  '<30',      'M', 'Y'],
# ['Chicago',     '[30-50)',  'M', 'Y'],
# ['New York',  '[30-50)',  'F', 'N'],
# ['Chicago',     '[30-50)',  'F', 'Y'],
# ['New York',  '[30-50)',  'F', 'N'],
# # ['Chicago',     '[50-80]', 'M', 'N'],
# ['New York',  '[50-80]', 'F', 'N'],
# ['New York',  '[50-80]', 'M', 'N'],
# ['Chicago',     '[50-80]', 'M', 'N'],
# ['New York',  '[50-80]', 'F', 'N'],
# ['Chicago',     '>80',      'F', 'Y']
# ]
# # require File.dirname(__FILE__) + '/../../lib/ai4r/classifiers/naive_bayes'
# # require File.dirname(__FILE__) + '/../../lib/ai4r/data/data_set'
# # require File.dirname(__FILE__) + '/../../lib/ai4r/classifiers/id3'
# # require 'benchmark'
#
#
# data_set = Ai4r::Data::DataSet.new(:data_items=>DATA_ITAMS, :data_labels=>DATA_LABELS)
# id3 = NaiveBayes.new.build(data_set)
#
# puts id3.eval(['New York', '<20' ])
# # id3.get_probability_map((['New York', '<30',])).each{|x| puts x.join(", ")}
a = [1,2]
a << 3
b = [a.dup,5]
a << 4

puts b
