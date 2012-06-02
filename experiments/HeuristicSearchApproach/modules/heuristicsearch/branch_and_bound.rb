require    File.dirname(__FILE__) +'/transitionselection.rb'
require    File.dirname(__FILE__) +'/query_components.rb'
require    File.dirname(__FILE__) +'/xnode.rb'



class BranchAndBound < XSearch
  @@path=[]
  def search()
    start = XNode.new("start",1)
    # @decision = DecisionTreeSelectionAlgorithm.new()
    xsearch(start)
    puts "##############################################"
    puts "TRANSITION HISTORY"
    XNode.transitions.each{|x|
      puts  x.to_s
      puts  x.history.to_s
    }
  end

  def local_path()
    @@path
  end

  def xsearch(start)
    while(start != nil)
      start = find(start)
      #solve for the instances that have been already found
      if $chunk == @@path.size
        XNode.solver.solve(@@path.map{|x| x.candidate.elements},@@path.map{|x| x.instance})
      @@path = []
      end
    end
    XNode.solver.solve(@@path.map{|x| x.candidate.elements},@@path.map{|x| x.instance})
    puts "DECISON RULES"
    # puts XNode.selector.instance_of? (DecisionTreeSelectionAlgorithm)
    # puts XNode.selector.get_rules() if XNode.selector.instance_of? DecisionTreeSelectionAlgorithm

    return @@path
  end

  def find(start)
    children = start.neighbors
    return nil if children.size == 0

    first=children.first

    nodes = []
    XNode.selector.restart()#save heap space. Before I create one instance for each xnode. it was too cost.

    cost = 0
    
    while children.size > 0 && cost != 1
      node = children.first
      if XNode.selector.process(node)
        puts "COMPUTING COST"
      cost = node.cost()
      # children = pruning(node,children)
        nodes << node
      end
      children.delete_at(0)
      if node.number < XNode.learningsize * 0.1
        cost = 0 #keep training all queries. Used for runking
      end 
    end

    # updatetime(nodes) #update the time of all transition that were executed
    best =  nodes.sort{|a,b| a.cost <=> b.cost}.first
    best =  nodes.find_all{|a| a.cost == best.cost }.sort{|a,b| a.transition.qtype <=> b.transition.qtype}.first

    return first if best == nil
    if best.cost != XNode::MAX_COST
      @@path << best
      XNode.selector.commit()
    end

    return  (best)
  end

  ##if current node retrieve
  def pruning(node, children)
    if node.cost == XNode::MAX_COST
      children.delete_if{|x| node > x}
    end
    children
  end

  def updatetime(nodes)
    # puts "TIME UPDATE"
    reverseorder =nodes
    reverseorder.each_index{|x|
    # puts reverseorder[x].transition
    # puts reverseorder[x].transition.history.timecost
      k=0
      for i in (x+1)..nodes.size-1
        reverseorder[x].transition.history.time+=reverseorder[i].transition.history.time
        k+=1
      end
      reverseorder[x].transition.history.time=(reverseorder[x].transition.history.time / k) if k > 0
    # puts reverseorder[x].transition.history.timecost
    }
  end

end

