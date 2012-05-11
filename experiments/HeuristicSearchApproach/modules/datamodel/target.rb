module QueryType
  EXACT=1
  BIF=2
  AND=3
  OR=4
end 

class CandidateSet
  include DataSourceModule
  attr_accessor :elements
  ##############################################################
  def initialize(transition,source)
    @transition=transition
    @elements = search(build(transition,source))
  end

  def build(transition,source)
    qc = ""
    qc = " ?s #{transition.qc.attribute} #{transition.qc.value} " if transition.qc != nil
    # qc = " ?s ?p #{transition.qc.value} " if transition.qc != nil

    attribute=transition.qa.attribute_alignment.target
    tokens = source.get_tokens(transition.qa.attribute_alignment.source)
    puts "KEYWORDS"

    puts tokens

    return nil if tokens.size == 0

    token = @token = tokens[0]

    lang = "@en" if $dbpedia
    query = case transition.qa.qtype
    when QueryType::EXACT then "SELECT DISTINCT ?s WHERE { ?s #{attribute}   '#{token.gsub(/'/,"\\\\'")}'#{lang} . #{qc}} limit 30"
    when QueryType::BIF then "SELECT DISTINCT ?s ?o  WHERE {  ?s #{attribute} ?o . ?o bif:contains  '\"#{token.gsub(/'/,"\\\\'")}\"' . #{qc}} limit 30"
    when QueryType::AND then
      k = token.keyword_normalization.split(" ")
      splited = k #if splited.size < 2
      splited.delete_if{|x| x.size == 1}
      if splited.size ==1
        "SELECT DISTINCT ?s WHERE { ?s #{attribute}   '#{token.gsub(/'/,"\\\\'")}'#{lang} . #{qc}} limit 30"
      else
        z= splited.map{|f| "\"#{f}\""}.join("AND")
        "SELECT DISTINCT ?s ?o WHERE {?s #{attribute} ?o . ?o bif:contains  '#{z.gsub(/'/,"\\\\'")}'  . #{qc}} limit 30"
      end

    when QueryType::OR then
      k = token.keyword_normalization.split(" ")
      splited = k #if splited.size < 2
      splited.delete_if{|x| x.size == 1}
      splited = splited + splited.map{|x| x.singularize}
      splited.uniq!
      if splited.size ==1
        "SELECT DISTINCT ?s WHERE { ?s #{attribute}   '#{token.gsub(/'/,"\\\\'")}'#{lang} . #{qc}} limit 30"
      else
        z= splited.map{|f| "\"#{f}\""}.join("OR")
        "SELECT DISTINCT ?s ?o WHERE {?s #{attribute} ?o . ?o bif:contains  '#{z.gsub(/'/,"\\\\'")}'  . #{qc}} limit 30"
      end
    else nil
    end
  end

  def search(query)
    puts "SEARCH"
    puts query
    b =[]
    return b if query == nil
    begin
      b = Query.new.adapters($session[:target]).sparql(query).execute
    rescue Exception => ex
      puts "Exception 52: #{ex}"
      puts ex.message
    end
    puts "TRANSITION TYPE"
    puts @transition.qtype
    if @transition.qtype !=  QueryType::EXACT
      b = filter(b,@token.to_s)
    end
    #faster way to get the triples from the endpoint
    b = union_query(b,$session[:target])

    # puts "CANDIDATES"
    # puts query
    # puts b
    b
  end

  def filter(data,keyword )
    puts "$filter_threshold"
    puts $filter_threshold
    data.uniq!
    # puts "Filtering ..."
    current=nil
    filtered=[]
    newdata =[]
    measure=false

    # data = yago_filter(data)   if params[:target] == "dbpedia"
    data=blank_node_remover(data)

    return newdata if data.size == 0

    subjects = data.map{|s,o| s}.uniq
    groupedsubject = subjects.map{|x| data.find_all{|s,o| s==x}}
    groupedsubject.each{|group|
      measure=false
      group.each{|s,o|
        score=0
        y = o.to_s

        score = advanced_string_matching(keyword,y)
        # puts keyword
        # puts score
        if score > $filter_threshold
        measure=true
        break
        end
      }
      if measure
      newdata = newdata + group
      end
    }
    newdata = newdata.map{|s,o| s}.uniq
    # newdata = yago_filter(newdata)   if $dbpedia
    return newdata
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
