#################################################################
class KnapsackItem
  attr_accessor :name, :cost ,:value ,:positive ,:negative, :all
  def initialize(name, positive, negative)
    @name=name
    @positive=positive
    @negative=negative
    @all=@positive+@negative
    @join=[]
  end

  def cost()
    weight(@negative, Knapsack.negatives)
  end

  def jaccard(x,y)
    return 1.0 if x.size ==0 and y.size ==0
    (((x&y).size.to_f))/(((x+y).uniq.size.to_f))
  end

  def weight(a,b)
    ((1.0 - jaccard(a,b)) * 100).round
  end
end

#################################################################
class Knapsack
  def initialize(positive_keys, negative_keys)
    keys = positive_keys.keys + negative_keys.keys
    keys.uniq!
    @items = []
    @@negatives=[]
    @@positives = []

    keys.each{|k|
      
      negative_keys[k] = [] if negative_keys[k] == nil
      positive_keys[k] = [] if positive_keys[k] == nil

      @@negatives = @@negatives + negative_keys[k]
      @@positives = @@positives + positive_keys[k]
      # puts "KEYS"
      # puts k
      @items << KnapsackItem.new(k, positive_keys[k], negative_keys[k])
    }
    cost_matrix = dynamic_programming_knapsack
    puts
    puts 'Dynamic Programming:'

    puts 'Found solution: ' + get_list_of_used_items_names( cost_matrix)
    puts 'With value: ' + cost_matrix.last.last.to_s

  end

  def self.negatives()
    @@negatives
  end

  def self.positives()
    @@positives
  end

  def jaccard(x,y)
    return 1.0 if x.size ==0 and y.size ==0
    (((x&y).size.to_f))/(((x+y).uniq.size.to_f))
  end

  def value(a)
    (jaccard(a, Knapsack.positives) * 100).round
  end

  def dynamic_programming_knapsack(v,w,W)
    V = zeros(n,W)
    n=v.size
     for i in (1..n)
       for w in (0..W)
         if (w[i] <= w) and (v[i] + V[i-1,w-w[i]]) > V[i-1,w]
           V[i,w] = v[i] + V[i-1,w-w[i]]
           keep[i,w]=1
         else
           V[i,w]=V[i-1,w]
           keep[i,w]=0
         end
       end
     end
     K=W
     for i in n..1
       if keep[i,K] == 1
         puts i
         K = K - w[i]
       end
     end
     return V[n,W]
  end 

  def zeros(rows, cols)
    Array.new(rows) do |row|
      Array.new(cols, [])
    end
  end
end
