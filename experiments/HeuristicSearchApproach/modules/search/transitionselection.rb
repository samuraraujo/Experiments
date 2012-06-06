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
class DecisionTreeSelectionAlgorithm
  attr_accessor :previous_node
  @@tree_reduction=nil
  @@tree_q2q=nil
  @@training_q2q=[]
  @@training_reduction=[]
  @@tmpq2q=[]
  @@tmpr=[]

  @@attributes =   ["Previous",  "Current","Sucess"]

  def initialize()
  end

  def restart()
    @previous_q2q = nil
    @previous_reduction=nil
    # @@tmp=[]
    @@tmpq2q=[]
    @@tmpr=[]
  end

  def commit()
    @@training_q2q = @@training_q2q + @@tmpq2q
    @@training_reduction = @@training_reduction + @@tmpr
    # puts "COMMITING"
  # @@training_q2q.each{|x| puts x.join(", ")}

  end

  def process(node)
    prediction = true
    # puts "################ PROCESSING #############"
    # puts @previous_reduction
    # puts node
    prediction=q2q(node)
    # prediction=reduction(node) if prediction
    return prediction
  end

  # def reduction(node)
    # prediction = true
    # if node.number >  XNode.learningsize * 0.1 && node.number < XNode.learningsize
      # if node.cost < XNode::MAX_COST
        # add_sample_reduction(@previous_reduction,node)
      # end
    # else
      # prediction = predict_reduction(@previous_reduction,node) if prediction
    # end
    # if prediction and node.cost < XNode::MAX_COST
    # @previous_reduction= node
    # end
# 
    # return prediction
  # end

  def q2q(node)
    prediction = true
    if  node.number < XNode.learningsize
      add_sample_q2q(@previous_q2q,node)
    else
      prediction = predict_q2q(@previous_q2q,node)
    end
    @previous_q2q = node
    return prediction
  end

  #creates an array representing the query data
  #[t1...tn,q,failure]
  def add_sample_q2q(a,b)
    # puts a
    # puts b
    row = []
    if a == nil
    row << -1 #no query performed yet
    # row << Xnode::MAX_COST+1
    # row << false
    # row << false
    else
    row <<  a.transition.object_id
    # row << (a.cost)
    # row << (a.passby ? false : (a.cost == 0))
    # row << (a.passby ? false : (a.cost == 1))
    end
    row << b.transition.object_id

    if (a == nil)
      if (b.cost == XNode::MAX_COST)
      row << 0
      else
      row << 1
      end
    elsif  a.cost <= b.cost
    row << 0
    else
    row << 1 
    end
    # puts "ADDING SAMPLE Q2Q"
    # puts  a.transition.qtype if a!=nil
    # puts  b.transition.qtype
    # puts row.join(", ")
    @@tmpq2q << row.map{|x| x.to_s}
  end

  # def add_sample_reduction(a,b)
  # # puts a
  # # puts b
  # row = []
  # if a == nil
  # row << -1 #no query performed yet
  # else
  # row <<  a.transition.object_id
  # end
  # row << b.transition.object_id
  # if a !=nil and a.cost <= b.cost
  # row << 0
  # else
  # row << 1
  # end
  # puts "ADDING SAMPLE REDUCTION"
  # puts  a.transition.qtype if a!=nil
  # puts  b.transition.qtype
  # puts row.join(", ")
  # @@tmpr << row.map{|x| x.to_s}
  # end

  #build vector to add in the tree or to predict
  def row_prediction(a,b)
    row = []
    if a == nil
    row << -1 #no query performed yet
    # row << XNode::MAX_COST+1
    else
    row << a.transition.object_id
    # row << a.cost
    end
    row <<  b.transition.object_id
    return row.map{|x| x.to_s}
  end

  def predict_q2q (a,b)
    return true if b.number < XNode.learningsize
    row = row_prediction(a,b)

    # puts "PREDICT Q2Q"
    # puts row.join(", ")
    if @@tree_q2q == nil
      data_set = Ai4r::Data::DataSet.new(:data_items=>@@training_q2q, :data_labels=>@@attributes)
      @@tree_q2q = Ai4r::Classifiers::NaiveBayes.new.build(data_set)
    end

    decision = @@tree_q2q.eval(row) == "1"

    # puts "Predicted: #{decision} ...";
    # @@tree.get_probability_map(row).each{|x| puts x.join(", ")}
    return decision
  end

  # def predict_reduction (a,b)
  # return true if b.number < XNode.learningsize
  # row = row_prediction(a,b)
  #
  # puts "PREDICT REDUCTION"
  # puts row.join(", ")
  # if @@tree_reduction == nil
  # data_set = Ai4r::Data::DataSet.new(:data_items=>@@training_reduction.uniq, :data_labels=>@@attributes)
  # @@tree_reduction = Ai4r::Classifiers::NaiveBayes.new.build(data_set)
  # end
  #
  # decision = @@tree_reduction.eval(row) == "1"
  # puts "Predicted: #{decision} ...";
  #
  # return decision
  # end

  # def discretizer(values)
    # # first determine the boundaries
    # f2bs = Hash.new { |h,k| h[k] = [] }
    # each_feature do |f|
      # fvs = values.sort
      # # number of samples in each interval
      # ns = (fvs.size.to_f/n_interval).round
      # fvs.each_with_index do |v, i|
        # if i%ns == 0
        # f2bs[f] << v
        # end
      # end
    # end
    # return values.map{|x|f2bs[f] }
  # end
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