module Serimi_Module
  def get_text_properties(rdfdata)

    puts "Computing text properties ... "

    data = Array.new(rdfdata)
    triples=[]
    data.each{|group|
      triples = triples + group
    }
    triples.uniq!
    triples.compact!
    textp=[]
    triples.each{|s,p,o| textp << p if o.to_s.size > 400}
    textp.uniq
  end

  ##############################################################################################################################
  def entity_label_filtering(rdfdata)
    $word_by_word_properties.delete("?p")
    discriminative_predicates=$word_by_word_properties
    if $word_by_word_properties.size == 0
      discriminative_predicates = target_discriminative_predicates(rdfdata) 
    end
    
    
    ######################## SELECTING RESOURCE WITH MAXIMUM STRING SIMILARITY MEASURE PER GROUP ##########################
    count=-1
    rdfdata.map!{|group|      
      
      count=count+1
      # puts "GROUP"
      if group.size > 0
        maximas = group.map{|s,p,o|
          entitylabel = discriminative_predicates.include?(p)
          entitylabel= true if discriminative_predicates.size == 0 # not enough information was used to compute the entropy
          entitylabel = true if (o.to_s.to_i != 0)
          [s,p,o, (!entitylabel || o.instance_of?(RDFS::Resource) or $textp.include?(p) ) ? 0 : (max_jaro(o.to_s, @searchedlabels[count],s).to_f ) ]   }
        # maximas = group.map{|s,p,o|  [s,p,o, (o.instance_of?(RDFS::Resource) or $textp.include?(p)  ) ? 0 : max_jaro(o.to_s, @searchedlabels[count],s).to_f ]   }

        max = maximas.map{|s,p,o,m| m.to_f }.max

        puts  "MAXIMA"
        puts max
        selection = []
        if max > $filter_threshold
          selection = maximas.map{|s,p,o,m| [s,p] if m == max }.uniq.compact
          $word_by_word_properties = selection.map{|s,p| p}.uniq +  $word_by_word_properties
          selection = selection.map{|s,p| s}.uniq
        end
        # selection = maximas.map{|s,p,o,m,e| s if m > $filter_threshold  }.uniq.compact
        # maximas = maximas.map{|s,p,o,m,e| [s,p,o,m,e] if m == max}.uniq.compact if max > $filter_threshold
        # max_entropy = maximas.map{|s,p,o,m,e| e }.max
        # selection = maximas.map {|s,p,o,m,e| s if   e == max_entropy}.uniq.compact  if max > $filter_threshold
        # puts maximas.map{|s,p,o,m| [s,o] if  m == max}.uniq
        # puts selection
        group.delete_if{|s,p,o|  !selection.include?(s)}.compact
        # puts "AFTER SELECTION"
        # puts group.map{|s,p| s}.uniq

        #Special processing for dbpedia due to redirect resources.
        #processing redirect resources

        # group = dbpedia_redirect(group)  if params[:target] == "dbpedia"
      end
      group

    }
    $word_by_word_properties.uniq!
    $word_by_word_properties.compact!
    $word_by_word_properties << "?p" if  $word_by_word_properties.size ==0
    # $word_by_word_properties=$word_by_word_properties[0..1]
    return rdfdata
  end

  def dbpedia_redirect(data)

    redirect = []

    data.each{|s,p,o| redirect << [s,o] if p.to_s.index("wikiPageRedirects") != nil }
    return data if redirect.size == 0
    redirect.uniq!
    subjects = redirect.map{|s,p| s}

    data.delete_if{|s,p,o| subjects.include?(s)   }
    redirect.each{|s,o|
      b= nil
      begin
        b =  Query.new.adapters($session[:target]).sparql("SELECT DISTINCT  ?p ?o  WHERE { #{o} ?p ?o  . } " ).execute
      rescue Exception => ex
        puts "Exception 3 for: #{o}"
        b =  Query.new.adapters($session[:target]).sparql("SELECT DISTINCT  ?p ?o  WHERE { #{o} ?p ?o  . } " ).execute
        puts "******************* EXCEPTION *****************"
        puts ex.message
      end
      b.map!{|p,x| [o,p,x]}
      data = data + b
    }
    data.uniq
  end

  #############################################################################################
  def max_jaro (a,labels,s)
    # puts "COMPUTING MAX JARO ... "
    # puts s
    c = 0
    # puts "LABELS"
    # puts labels
    # puts "-------"
    labels.each{|x|
     
      c = c + advanced_string_matching(a, x)
    }
    # puts a
    # puts c
    c
  end

  require 'date'

  def valid_date?( str)
    Date.strptime(str,"%m/%d/%Y" ) rescue Date.strptime(str,"%Y-%m-%d" )  rescue false
  end

  ##############################################################
  def get_ambiguous(subjects, labelproperties)
    puts "ORIGIN LABEL PROPERTIES"
    puts labelproperties
    @searchedlabels = []
    # subjects.delete_if{|x| x[0].class.to_s == 'BNode'  }
    data = subjects.map{|s| 
      $log_subjects.write(s.to_s.gsub("<","").gsub(">",""))
      $log_subjects.write("\n") 
      puts s
     
      el = []
      keywords= []
      ambiguous = []
      labelproperties.each{|labelproperty|
        keywords= []
        begin
          keywords = keywords + Query.new.adapters($session[:origin]).sparql("select distinct ?o where { #{s} #{labelproperty} ?o. }").execute.flatten.compact
        rescue Exception => e
          puts "Exception for: select distinct ?o where { #{s} #{labelproperty} ?o. }"
          keywords = keywords + Query.new.adapters($session[:origin]).sparql("select distinct ?o where { #{s} #{labelproperty} ?o. }").execute.flatten.compact
        end
        keywords.compact!
        keywords.delete_if {|b| b.to_s.size > 150 } # eliminates text
        keywords.delete_if {|b| b.class.to_s == 'BNode' } # eliminates text
        keywords.delete_if {|b| valid_date?(b.to_s) != false } # eliminates date
        keywords=keywords.map {|b| b.split("(")[0].to_s.rstrip } # eliminates everything between parenteses.
        
        keywords.uniq!

        ambiguous = search(keywords)
        puts "Searched Ambiguous"

        break if ambiguous.compact.size > 0
      }
      # I added the ext_keywords because the string threshold can be too high for some cases.
      # I decided to do that because I found problem in the nytimes-freebase people interliking.
      @searchedlabels << keywords

      ambiguous.compact.uniq.each{|a| el = el + a}
      el.uniq
    }

    $textp = get_text_properties(data) if $textp == nil
    puts "TEXT PROPERTIES USED"
    puts $textp
    puts "END"

    entity_label_filtering(data)

    remove_idx = []
    data.each_index{|x|
    #            puts "############ 111"
    #             puts subjects[x]
    #            puts data[x]
    #            puts "############ 222"
      remove_idx << x if data[x].size == 0
    }
    remove_idx.reverse.each{|x|
      @searchedlabels.delete_at(x)
      subjects.delete_at(x)
      data.delete_at(x)
    }
    $criteria_keyword = @searchedlabels
    
    [subjects,data]
  end

  ##############################################################################################################################
  def get_first_pivot(instances,limit, offset, labels)
    puts "Obtaining First Pivot"
    resources  = get_ambiguous($instances[offset..(offset+limit-1)], labels)

    subjects = resources[0]
    data = resources[1]
    return if data.size == 1 or data.size == 0
 
    $origin_subjects =  subjects.map{|s|
      begin
        Query.new.adapters($session[:origin]).sparql("select distinct ?p ?o where { #{s} ?p ?o. }").execute
      rescue Exception => e
        puts "Exception 2 for: #{s}"
        e.message
        Query.new.adapters($session[:origin]).sparql("select distinct ?p ?o where { #{s} ?p ?o. }").execute
      end
    }
    rdf2svm_with_meta_properties(data , [])

    puts "End of Obtaining First Pivot"
  end

  ## GET ENTITY LABELS
  def source_entity_labels(instances)
    puts "source_entity_labels"
    data=[]
    count =0
    instances.each {|s|
      tmp =  Query.new.adapters($session[:origin]).sparql("select ?p ?o where {  #{s.to_s} ?p ?o }").execute
      tmp.map! {|p,o| [s,p,o] }
      data= data + tmp
    }

    $textp = get_text_properties([data])
    puts $textp

    data.map! {|s,p,o| [s,p,o] if !$textp.include?(p) }.compact.uniq
    labels = []
    candidates = entropy_computation([data])[0]
    puts "SOURCE CANDIDATES ENTITY LABELS"
    puts candidates

    data.each{|s,p,o|

      labels << p if !$textp.include?(p) and candidates.include?(p) and o.instance_of?(String) and o.size > 3 and (o.to_i.to_s.size != o.to_s.size and o.to_f.to_s.size != o.to_s.size)  #and (o.to_i == 0)
    }
    labels.uniq!

    $textp=nil
    labels.uniq!
    labels = candidates.delete_if{|x| !labels.include?(x)}.compact
    puts "ENTITY LABELS FOUND"
    puts labels
    labels=labels[0..2]
    puts "ENTITY LABELS SELECTED"
    labels.insert(0,"<http://www.w3.org/2000/01/rdf-schema#label>")
    labels.map!{|x| x.to_s}
    labels.uniq!
    puts labels

    labels[0..4]

  end

  ## GET ENTITY LABELS
  def target_discriminative_predicates(instances)
    puts "target_discriminative_predicates"
    count =0
    data=[]
    instances.each{|group|
      data = data + group
    }
    data.map! {|s,p,o| [s,p,o] if !$textp.include?(p) }.compact.uniq
    labels = []
    candidates = entropy_computation([data])[0]
    puts "TARGET CANDIDATES DISCRIMINATIVE PREDICATES"
    puts candidates

    data.each{|s,p,o|

      labels << p if !$textp.include?(p) and candidates.include?(p) and o.instance_of?(String) and o.size > 3 and (o.to_i.to_s.size != o.to_s.size and o.to_f.to_s.size != o.to_s.size)  #and (o.to_i == 0)
    }

    labels.uniq!
    labels = candidates.delete_if{|x| !labels.include?(x)}.compact
    puts "TARGET  DISCRIMINATIVE PREDICATES FOUND"
    labels.uniq!
    puts labels

    labels

  end

  def get_stop_words(instances, labels)
    puts "STOP WORDS"

    all_stopwords=[]

    labels.each{|label|
      data=[]
      puts "STOP WORDS FOR LABEL: "
      puts label
      stopwords=[]
      size = instances.size
      offset = 0
      while offset < size
        q = instances[offset..(offset+50)].map {|x| " {#{x.to_s} #{label} ?o}"  }.join(" union ")
        data = data +  Query.new.adapters($session[:origin]).sparql("select ?o where { #{q} }  ").execute
        offset = offset+50
      end
      # puts data
      next if data.size == 0
      words=Hash.new

      str = data.map{|o| o.to_s.keyword_normalization.split(" ")}.flatten
      str.each{|x|
        next if x.to_i != 0
        next if x == nil
        # puts x
        words[x] = 0 if words[x] == nil
        words[x] = words[x] + 1
      }
      next if words.size == 0
      size = data.size
      puts "SIZE"
      puts size
      words.each{|x,v|
      # puts x
      # puts v
        words[x] = v.to_f / size.to_f
      }
      # words.sort.each{|x,v|
      # puts x
      # puts v
      #
      # }
      puts "MEDIA / STDEV"
      mm =  mean_and_standard_deviation(words.values)
      mean= mm[0].to_f
      stdev = mm[1].to_f

      puts mean
      puts stdev
      puts "Threshold"
      threshold = mean
      puts threshold
      next if stdev < (mean * 2)
      words = sort(words)
      words.each{|x,v|
      # puts x
      # puts v
        x = x.keyword_normalization.removeaccents
        stopwords << x if v >= (threshold) and x.size > 1
      } #if stdev > 0.1
      stopwords.uniq!
      stopwords =stopwords.sort_by{|x| x.size}
      stopwords.reverse!

      puts stopwords
      puts "END"
      puts stopwords.size
      all_stopwords=all_stopwords + stopwords
    }
    all_stopwords
  end

  ####################################
  def getCode(v)
    ####################################
    #    puts "Getting Code"
    #    @codes=Array.new if @codes == nil
    #    index = @codes.index(v)
    #    return index if index != nil
    #    @codes << v
    #    return @codes.size-1
    ####################################
    @counter=0 if @counter == nil
    @codes=Hash.new if @codes == nil
    c = @codes[v]
    if c == nil
    @counter=@counter+1
    @codes[v]=@counter
    c=@counter
    end
    ####################################
    return  c
  end

end