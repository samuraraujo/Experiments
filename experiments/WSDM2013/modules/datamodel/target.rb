module QueryType
  EXACTLANG=1
  EXACT=2
  BIF=3
  AND=4
  OR=5
  CAPITALIZE=6
  DOWNCASE=7
  UPCASE=8
  NONE=9
end
class CandidateSet
  include DataSourceModule
  attr_accessor :elements
  ##############################################################
  def initialize(transition,instance)
    @transition=transition
    @elements=[]
    puts "TOKENS"
    CandidateSet.getTokens(instance, transition.qa.attribute_alignment.source).each{|token|
      puts token
      next if @elements.size > 0
      @elements = search(build(transition,token))
      if @elements.size > 0
      @transition.history.addToken(token)
      end
    }

  end

  def self.getTokens(source,attribute)
    tokens = source.get_tokens(attribute)
    # puts "KEYWORDS"
    # puts tokens
    tokens
  end

  def build(transition,token)
    qc = ""
    qc = " ?s #{transition.qc.attribute} #{transition.qc.value} " if transition.qc != nil
    # qc = " ?s ?p #{transition.qc.value} " if transition.qc != nil

    attribute=transition.qa.attribute_alignment.target
    
    # return nil if tokens.size == 0

    @token = token.to_s
    # pay attention because the search token is different from the filter token (original token used on string matching)
    token= token.split("(")[0].to_s.rstrip # eliminates everything between parenteses.
    query =  case transition.qa.qtype
    when QueryType::EXACTLANG then "SELECT DISTINCT ?s WHERE { ?s #{attribute}   '#{token.gsub(/'/,"\\\\'")}'@en . #{qc}} limit #{$sparqllimit}"
    when QueryType::EXACT then "SELECT DISTINCT ?s WHERE { ?s #{attribute}   '#{token.gsub(/'/,"\\\\'")}' . #{qc}} limit #{$sparqllimit}"
    when QueryType::BIF then "SELECT DISTINCT ?s ?o  WHERE {  ?s #{attribute} ?o . ?o bif:contains  '\"#{token.gsub(/'/,"\\\\'")}\"' . #{qc}} limit #{$sparqllimit}"
    when QueryType::AND then
      k = token.keyword_normalization.split(" ")
      # splited = k #if splited.size < 2
      splited = k - $stopwords
      splited = k if splited.size == 0 
      splited.delete_if{|x| x.size < 3}

      z= splited.map{|f| "\"#{f}\""}.join("AND")
      "SELECT DISTINCT ?s ?o WHERE {?s #{attribute} ?o . ?o bif:contains  '#{z.gsub(/'/,"\\\\'")}'  . #{qc}} limit #{$sparqllimit}"

    when QueryType::OR then
      k = token.keyword_normalization.split(" ")
      # splited = k #if splited.size < 2
      splited = k - $stopwords
      splited = k if splited.size == 0
       splited.delete_if{|x| x.size < 3}
      splited = splited + splited.map{|x| x.singularize}
      splited.uniq!

      z= splited.map{|f| "\"#{f}\""}.join("OR")
      "SELECT DISTINCT ?s ?o WHERE {?s #{attribute} ?o . ?o bif:contains  '#{z.gsub(/'/,"\\\\'")}'  . #{qc}} limit #{$sparqllimit}"

    else nil
    end

    return query
  end

  def search(query)

    b =[]
    return b if query == nil

    next if b.size > 0
    begin
      b = Query.new.adapters($session[:target]).sparql(query).execute
    rescue Exception => ex
      puts "Exception 52: #{ex}"
      puts ex.message
    end
    
    b = yago_filter(b)   if $isdbpedia
    
    if @transition.qtype !=  QueryType::EXACT && @transition.qtype !=  QueryType::EXACTLANG
        b = filter(b,@token.to_s)
       
    end
    
    #faster way to get the triples from the endpoint
    b = union_query(b,$session[:target])

    # puts "CANDIDATES"
    # puts query
    # puts b
    b
  end

def filter(data,keyword)
    puts "$filter_threshold"
    puts $filter_threshold
    data.uniq!
    # puts "Filtering ..."
    current=nil
    filtered=[]
    newdata =[]
    measure=false 
    maxscore=0
    
    data=blank_node_remover(data)

    return newdata if data.size == 0

    subjects = data.map{|s,o| s}.uniq
    groupedsubject = subjects.map{|x| data.find_all{|s,o| s==x}}
    groupedsubject.each{|group|
      measure=false
       score=0
      group.each{|s,o|
        
        y = o.to_s   
        score = advanced_string_matching(keyword,y) 
        # puts keyword
        # puts y
        # puts score
        if score > $filter_threshold
          maxscore = score if score > maxscore 
        measure=true
        # exit
        break 
        end
      }
      if measure 
      newdata = newdata + group.map{|s,o| s}.uniq.map{|s| [s,score]}
      end
    }
    newdata.delete_if{|s,o| o < maxscore}
    newdata = newdata.map{|s,o| s}.uniq 
    return newdata
  end
  # def filter(data,keyword)
    # puts "$filter_threshold"
    # puts $filter_threshold
    # data.uniq!
    # # puts "Filtering ..."
    # current=nil
    # filtered=[]
    # newdata =[]
    # measure=false 
#      
#     
    # data=blank_node_remover(data)
# 
    # return newdata if data.size == 0
# 
    # subjects = data.map{|s,o| s}.uniq
    # groupedsubject = subjects.map{|x| data.find_all{|s,o| s==x}}
    # groupedsubject.each{|group|
      # measure=false
      # group.each{|s,o|
        # score=0
        # y = o.to_s   
        # score = advanced_string_matching(keyword,y) 
        # if score > $filter_threshold
        # measure=true
        # # exit
        # break 
        # end
      # }
      # if measure 
      # newdata = newdata + group
      # end
    # }
    # newdata = newdata.map{|s,o| s}.uniq 
    # return newdata
  # end
 def yago_filter(data)  
    data.delete_if{|s,p,o|  s.to_s.index("/yago/") != nil }
    data.compact!
    data
  end
  ######################################################
  def blank_node_remover(data)
    data.delete_if{|s,o|   s.class.to_s == 'BNode'  }

    # blanknodes.each{|b|
    #
    # result=Query.new.adapters($session[:target]).sparql("SELECT DISTINCT ?s ?p ?o  WHERE { ?s ?p ?o . ?o #{data.find_all{|s,p,o| s==b and o.class == String}.map{|s,p,o| [p,o]}.first.join(' ')}  . } " ).execute
    # exit
    # expanded_subjected=result.first.first
    # data.map!{|s,p,o|
    # if s==b
    # [expanded_subjected,p,o]
    # else
    # [s,p,o]
    # end
    # }
    # data = data + result
    # }

    return data
  end
end

