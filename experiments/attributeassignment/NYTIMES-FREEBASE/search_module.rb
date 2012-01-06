require "matching_module.rb"

def get_all_instances(klass , limit)
  t0 =  Time.now
  instances = []
  orderbyclause = "}"
  orderbyclause = $orderbyclause if $experiment && $orderbyclause != nil
  orderby = $orderby if $experiment && $orderby != nil
  count =  Query.new.adapters($session[:origin]).sparql("select distinct count(distinct ?s) where {?s ?p #{klass} . #{orderbyclause} ").execute[0][0].to_i
  retrieved = 0
  limit = count if limit == nil
  while retrieved < count && retrieved < limit
    results = Query.new.adapters($session[:origin]).sparql("select distinct ?s where {?s ?p #{klass} .   #{orderbyclause} #{orderby} offset #{retrieved } limit #{limit }" ).execute
    retrieved  = retrieved + results.size
    # puts "RESULTS SIZE"
    # puts results.size
    instances = instances + results.map{|x| x.to_s}
  end
  instances.uniq!
  puts "Elapsed time"
  puts Time.now - t0
  instances
end



def intersection_query(subjects, dataset)
  q = subjects.map {|x| "   #{x.to_s}  ?p  ?o . "  }.join(" ")
  return [] if q == ""
  data =  Query.new.adapters(dataset).sparql("select distinct * where { #{q} }  ").execute
end



def union_query(subjects, dataset)
  subjects.delete_if{|x| x[0].class.to_s == 'BNode'}
 
  size = subjects.size
  offset = 0
  data=[]
  while offset < size
    q = subjects[offset..(offset+30-1)].map {|x| " { ?s  ?p  ?o . filter (?s = #{x.to_s}) }"  }.join(" union ")
    return [] if q == ""
    data = data + Query.new.adapters(dataset).sparql("select distinct * where { #{q}}  ").execute
    offset = offset+30
  end
  return data
end



#search for resources

def search(keywords)

  puts "KEYWORDS"
  puts keywords
  # $word_by_word_properties =[ "<http://www.w3.org/2000/01/rdf-schema#label>"]
  puts "TARGET LABEL PROPERTIES"
  puts $word_by_word_properties
  data=[]
  # keywords=keywords.map {|b| b.split("(")[0].to_s.rstrip } # eliminates everything between parenteses
  keywords.each{|x|

    x.gsub!("*"," ")
    x.gsub!(/"/,"")
    next if x.size < 3
    # if x.index ("singapore") != nil
    # puts $offset
    # exit
    # return
    # end
    b=[]
    # $label.each{|h|
    # puts "FOUND KEYS"
    # puts $word_by_word_properties

    puts "exact_search"
    b = exact_search(x)

    if b.size == 0   #applies exact_bif_search
      puts "exact_bif_search"
      b = exact_bif_search(x)
    end
    if b.size == 0   #applies word by word approach
      puts "and_search"
      b = and_search(x)
    end
    if  b.size == 0 and $word_by_word #applies word by word approach
      puts "word_by_word_search"
      b = word_by_word_search(x)
    end
    # if  b.size == 0  #applies suffix removal approach
    # puts "suffix_removal_search"
    # b = suffix_removal_search(x, h)
    # end
    b.uniq!
    # puts b.size
    # puts b
    # b = dbpedia_filter(b) if params[:origin] == "dbpedia" || params[:target] == "dbpedia"
    data << b
  # puts data.size
  # puts data

  }
  data.map!{|t| t if t[0] != nil}
  data.compact!
  data
end



def exact_search(x)
  b=[]
  pre=nil
  lang = "@en" if $dbpedia
  $word_by_word_properties.each{|pre|
    begin
      b = b + Query.new.adapters($session[:target]).sparql("SELECT DISTINCT ?s WHERE { ?s #{pre}   '#{x.gsub(/'/,"\\\\'")}'#{lang} . #{$criterias}} limit 30" ).execute
      # b = b + Query.new.adapters($session[:target]).sparql("SELECT DISTINCT ?s WHERE { ?s ?p   '#{x.gsub(/'/,"\\\\'")}'#{lang} . #{$criterias}} limit 30" ).execute
    rescue Exception => ex
      puts "Exception 52: #{x}"
      puts ex.message

    end

    break if b.size > 0
  }
  $word_by_word_properties.insert(0,pre) if pre != nil
  $word_by_word_properties.uniq!
  b = union_query(b,$session[:target])

  b
end



def exact_bif_search(x)
  b=[]
  pre=nil
  $word_by_word_properties.each{|pre|
    begin
      b = b + Query.new.adapters($session[:target]).sparql("SELECT DISTINCT ?s ?o  WHERE {  ?s #{pre} ?o . ?o bif:contains  '\"#{x.gsub(/'/,"\\\\'")}\"' . #{$criterias}} limit 30" ).execute

      # b = b + Query.new.adapters($session[:target]).sparql("SELECT DISTINCT ?s ?e ?h  WHERE { ?s ?e ?r . ?s #{h} ?o . ?o bif:contains  '\"#{x.gsub(/'/,"\\\\'")}\"'  . ?r ?g ?h } " ).execute
      # puts b
    rescue Exception => ex
      puts "Exception 51: #{x}"
      puts ex.message
      b = b + Query.new.adapters($session[:target]).sparql("SELECT DISTINCT ?s ?o  WHERE { ?s #{pre} ?o . ?o bif:contains  '\"#{x.gsub(/'/,"\\\\'")}\"' . #{$criterias}} limit 30 " ).execute
    end
    b = filter(b,x.to_s)
    break if b.size > 0
  }
  $word_by_word_properties.insert(0,pre)if pre != nil
  $word_by_word_properties.uniq!
  b = union_query(b,$session[:target])

  b
end



def and_search(x)
  b=[]
  pre=nil
  # $criterias=nil
  $word_by_word_properties.each{|pre|
    k = x.keyword_normalization.split(" ")
    # splited = k - $stopwords
    splited = k #if splited.size < 2
    # puts splited

    while b.size == 0
      break  if splited.size < 2
      z= splited.map{|f| "\"#{f}\""}.join("AND")

      begin
        b = Query.new.adapters($session[:target]).sparql("SELECT DISTINCT ?s ?o WHERE {?s #{pre} ?o . ?o bif:contains  '#{z.gsub(/'/,"\\\\'")}'  . } limit 30" ).execute
      rescue Exception => ex
        puts "Exception 52: #{x}"
        puts ex.message
        b = Query.new.adapters($session[:target]).sparql("SELECT DISTINCT ?s ?o WHERE {  ?s #{pre} ?o . ?o bif:contains  '#{z.gsub(/'/,"\\\\'")}'  . } limit 30" ).execute
      end
      b = filter(b,x.to_s)
      splited.delete_at(splited.size-1)
    end
  }
  ######################
  c=[]
  $word_by_word_properties.each{|pre|
    k = x.keyword_normalization.split(" ")
    splited = k - $stopwords
    break  if splited.size < 2
    z= splited.map{|f| "\"#{f}\""}.join("AND")

    begin
      c= Query.new.adapters($session[:target]).sparql("SELECT DISTINCT ?o WHERE { ?s #{pre} ?o . ?o bif:contains  '#{z.gsub(/'/,"\\\\'")}'  . } limit 30" ).execute
    rescue Exception => ex
      puts "Exception 52: #{x}"
      puts ex.message
      c = Query.new.adapters($session[:target]).sparql("SELECT DISTINCT ?s ?o  WHERE { ?s #{pre} ?o . ?o bif:contains  '#{z.gsub(/'/,"\\\\'")}'  . } limit 30" ).execute
    end
    c = filter(c,x.to_s)
    break if c.size > 0
  }
  $word_by_word_properties.insert(0,pre)if pre != nil
  $word_by_word_properties.uniq!
  return union_query(b + c,$session[:target])
end



def word_by_word_search(x)
  b=[]
  pre=nil
  splited = x.keyword_normalization.split(" ")
  splited.each{|z|
    next if $stopwords.include?(z.removeaccents)
    next if z.size < 3
    c=[]
    $word_by_word_properties.each{|pre|
      next if c.size > 0
      begin
        c = Query.new.adapters($session[:target]).sparql("SELECT DISTINCT ?s ?o WHERE {  ?s #{pre} ?o . ?o bif:contains  '\"#{z.gsub(/'/,"\\\\'")}\"'  . } limit 30" ).execute
      rescue Exception => ex
        puts "Exception 52: #{x}"
        puts ex.message
        c = Query.new.adapters($session[:target]).sparql("SELECT DISTINCT ?s ?o  WHERE {  ?s #{pre} ?o . ?o bif:contains  '\"#{z.gsub(/'/,"\\\\'")}\"'  . } limit 30 " ).execute
      end
      c = filter(c,x.to_s)
      b = b + c
    # return b if b.size > 0  and $stopwords.size == 0
    }
    break if b.size > 0
  }
  $word_by_word_properties.insert(0,pre)if pre != nil
  $word_by_word_properties.uniq!
  b= union_query(b,$session[:target])
  b
end



################################### FILTER ###################################################

def filter(data,keyword )
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



###### Filtering Criterias
def build_criterias(subjects,data)
  # return "?s a <http://dbpedia.org/ontology/Film> "
  return ""
  return nil if subjects == nil || subjects.size == 1
  puts "SUBJECTS"
  puts subjects
  # a = intersection_query(subjects[0..5],$session[:target])

  triples = []
  data.each{|x| triples = triples + x }

  triples.delete_if {|s,p,o|  !subjects.include?(s) || !o.instance_of?(RDFS::Resource)}
  entropies = entropy_computation([triples])
   
  predicate = entropies[2].last 
 
  triples.delete_if{|s,p,o| predicate.to_s != p.to_s  }
  triples.map!{|s,p,o| "?s #{p} #{o} . "  }

  freq = triples.inject(Hash.new(0)) { |h,v| h[v] += 1; h }
  criteria =  triples.sort_by { |v| freq[v] }.last
  puts "SELECTEDS"
  puts criteria
  # exit
  # previous = nil
  # criteria = nil
  # keyword = $criteria_keyword[0]
  # intersection.each{|x|
  # c = Query.new.adapters($session[:target]).sparql("SELECT DISTINCT count(distinct ?s)  WHERE {  ?s ?p ?o . ?o bif:contains  '\"#{keyword.gsub(/'/,"\\\\'")}\"'  . #{x} }  " ).execute[0][0].to_i
  # previous = c + 1  if previous == nil
  # if c < previous and c > 0
  # criteria = x
  # end
  # }
  return criteria
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


# 
# def yago_filter(data)
  # puts "REMOVING yago ..."
  # # puts data.size
  # data.delete_if{|s|  s.to_s.index("yago") != nil }.compact!
  # data
# end

