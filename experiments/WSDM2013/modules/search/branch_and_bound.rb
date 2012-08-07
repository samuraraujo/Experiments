require    File.dirname(__FILE__) +'/transitionselection.rb'
require    File.dirname(__FILE__) +'/query_components.rb'
require    File.dirname(__FILE__) +'/xnode.rb'

class BranchAndBound < XSearch
  def search()
    @@candidates=[]
    @@instances=[]

    start = XNode.new("start",1)
    # @decision = DecisionTreeSelectionAlgorithm.new()
    xsearch(start)
    puts "##############################################"
    puts "TRANSITION HISTORY"
    XNode.transitions.each{|x|
      ww  x.to_s
      x.history.print
    }
  end

  def local_path()
  end

  def xsearch(start)
    classupdated= false

    $totalsearchtime=0
    $matchertotaltime=0
    @targetkeys = XNode.transitions.map{|x| x.qa.attribute_alignment.group }.uniq
    chunk = 20 #first chunk is 20 elements. It is used to generate the class queries
    
    while(start != nil)
      
      t0 = Time.now
      
      begin
      start = xxfind(start)
      rescue Exception => e
        p e.message
         p e.backtrace.inspect  
        p "exception"
        exit
      end
      
      $totalsearchtime += (Time.now - t0)

      
      #solve for the instances that have been already found
      if chunk == @@instances.size
        chunk = $chunk
        t0=Time.now
        solution = XNode.solver.solve(@@candidates, @@instances)
        $matchertotaltime+=(Time.now - t0)
        # $aligner.relearngroups(solution,@@candidates) if refinegroups
        classupdated=update_transitions(solution) if !classupdated && $transitionupdate
      # exit
      @@candidates=[]
      @@instances=[]
      end
    end
    XNode.solver.solve(@@candidates, @@instances)
    return nil
  end

  def xxfind(start)
     
    children = start.neighbors
    return nil if children.size == 0

    first=children.first

    nodes = Hash.new
    cost = Hash.new
    XNode.selector.restart()#save heap space. Before I create one instance for each xnode. it was too cost.

    @targetkeys.each{|x|
      nodes[x]=[]
      cost[x]=0
    }
     

    while children.size > 0
      node = children.delete_at(0)
      key = node.transition.qa.attribute_alignment.group
      next if cost[key] == $topk and $topk > 0
      next if $topk == 0 and cost[key] > 0  and cost[key] != XNode::MAX_COST
      candidates = []
      if  XNode.selector.process(node)
        puts "COMPUTING COST"
      cost[key] = node.cost()
      # children = pruning(node,children)

      nodes[key] << node
      end

    # if node.number < XNode.learningsize * 0.1
    # cost[key]  = 0 #keep evaluating all queries during the ranking and training phase
    # end
    end
     
    nodes = nodes.values.map{|x|
    # updatetime(x) if  NaiveBayesClassifier.learning
      x.sort{|a,b| a.cost <=> b.cost}.first
    }.compact
    
    best =  nodes.sort{|a,b| a.cost <=> b.cost}.first
    
    return first if best == nil
    
    if best.cost != XNode::MAX_COST
      candidates = []
      nodes.each{|x|
        candidates = candidates + x.candidate.elements
      }
       
      @@candidates << candidates.uniq
      
      @@instances << first.instance
      
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

