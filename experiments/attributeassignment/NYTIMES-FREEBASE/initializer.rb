#Serimi Functionalities.
#Author: Samur Araujo
#Date: 10 April 2011.
#License: SERIMI is distributed under the LGPL[http://www.gnu.org/licenses/lgpl.html] license.
require '../../../active_rdf/lib/active_rdf'
require '../../../activerdf_sparql-1.3.6/lib/activerdf_sparql/init'
require '../endpoints.rb'
require 'active_support/inflector'
require "search_module.rb"
require 'attribute-assign.rb'
require "./logger.rb"

$session = Hash.new
module Initializer_Module
  def initialize(params)
    create_log()
    puts "Parameters:"

    params.each { |k,v| puts "#{k} => #{v}" }

    $usepivot=false
    $topk=params[:topk].to_i
    $output=params[:output] if $output == nil
    $format=params[:format]
    $filter_threshold=params[:stringthreshold]
    $rdsthreshold=params[:rdsthreshold]
    $usepivot=true if params[:usepivot] ==  'true'
    $blocking=true  if params[:blocking] ==  'true'
    if params[:append] == 'w'
      File.delete($output) if  File.exist?($output)
    end

    $instances = []
    totallimit =nil
    $removelabels=[]

    $t1=Time.now
    count = 0
    manual_offset=params[:offset]

    params[:source] = $endpoints[params[:source].to_sym] if params[:source].downcase.index("http") == nil
    params[:target] = $endpoints[params[:target].to_sym] if params[:target].downcase.index("http") == nil

    origin_endpoint=params[:source]
    target_endpoint=params[:target]

    $dbpedia = params[:target].index("dbpedia") != nil

    $session[:origin] = mount_adapter(origin_endpoint,:post,false)
    $session[:target] = mount_adapter(target_endpoint,:post,false)

    limit = $TH = params[:chunk]

    $textp = nil

    klass =  params[:class]
    klass =  "<"+ params[:class] + ">" if  params[:class].index("<") == nil

    start = true
    delete = true
    # $lastclass=nil

    puts "PROCESSING CLASSES"
    puts klass
    puts " LAST CLASS"
    puts $lastclass
    $pivot = []
    $bdata=nil
    $word_by_word_properties=["?p"]
    $pivot_labels = []
    $pivot_subjects = []
    if $lastclass != nil && start
      next if s != $lastclass
    start = false
    end

    $lastclass= klass

    puts "Obtaning all instances instances"
    $instances = get_all_instances(klass,totallimit)

    $instances = experiment_instances($instances) if $experiment

    count = $instances.size
    puts "TOTAL NUMBER OF INSTANCES"
    puts count
    puts "SOURCE PROCESSING ##################"
    labels = source_entity_labels($instances[0..20])
    $stopwords=get_stop_words($instances[0..500],labels)

    offset = 0
    puts  "PREVIOUS OFFSET"
    puts $offset

    # manual_offset= count - 50
    # manual_offset=975

    $offset=manual_offset if manual_offset > 0 and $offset == nil
    offset = $offset.to_i  if $offset != nil

    puts "STARTING FROM OFFSET " + offset.to_s
    puts "NUMBER OF INSTANCES"
    puts count
    puts "TARGET PROCESSING ##################"
    #GET FIRST PIVOT
    limit = count if limit > count
    get_first_pivot($instances,10, offset, labels) if $usepivot
    while offset <= count and limit <= count   do
      # sleep 1.5
      # if offset == 0
      # limit = 5
      # elsif offset == 5
      # limit = $TH
      # end
      puts "OFFSET"
      $offset=offset
      puts offset
      puts "LIMIT"
      puts limit

      RDFS::Resource.reset_cache()
      $ifp=nil

      resources  = get_ambiguous($instances[offset..(offset+limit-1)], labels)

      offset=offset+limit
      subjects = resources[0]
      data = resources[1]
      if data.size == 1 and offset < count and limit < 100
        offset=offset-limit
        limit = limit + limit
        if offset == 0
        offset = 5
        limit = limit + offset
        end
        puts "CHANGING LIMIT TO " + limit.to_s
      next
      end
      next if data.size == 1 or data.size == 0

      xxx =[]
      $instances[0..10].each {|s|
        tmp =  Query.new.adapters($session[:origin]).sparql("select ?p ?o where {  #{s.to_s} ?p ?o }").execute
        tmp.each {|p,o| xxx << [s,p,o] }
      }

      triples=[]
      data.each{|group|
        triples = triples + group
      }
      triples.uniq!
      # puts triples.size
      # puts triples[0]
      # exit
      assingment(xxx,triples)
      exit
      # string_matching_alignment_result(data,subjects)
      web_build_sample(data,subjects)

      $criterias= build_criterias($selecteds, data) #if  $criterias == nil
      puts "CRITERIA"
      puts $criterias
    # exit if $criterias != nil

    # break if offset > 20
    # break
    end
    puts "LAST OFFSET PROCESSED"
    puts $offset
    puts limit
    $offset =nil
    $lastclass=nil

    puts $t2=Time.now

    starttime_sec= $t1.strftime("%S").to_i
    starttime_min= $t1.strftime("%M").to_i
    endtime_sec= $t2.strftime("%S").to_i
    endtime_min= $t2.strftime("%M").to_i
    diff_sec= endtime_sec - starttime_sec
    diff_sec1= diff_sec.to_s
    diff_min= endtime_min - starttime_min
    diff_min1= diff_min.to_s
    puts "\nElapsed time:\n "+ "Min-> " +diff_min1 + " Sec-> "+ diff_sec1
    puts $t2-$t1
    puts "NUMBER OF INSTANCES PROCESSED"
    puts count
    close_log
  end

  #####################################################################################################
  def web_build_sample(data,subjects)
    $selecteds=[]

    puts "**************************** BUILDING SAMPLE"
    puts data.size
    puts "*************************** PIVOT SIZE"
    puts $pivot.map{|x| x.map{|s,p| s}.uniq}
    pivot_size = $pivot.size

    results = union_query(subjects, $session[:origin])
    $origin_subjects = subjects.map{|x|
      results.find_all{|s,p,o| s.to_s==x.to_s}
    }

    @searchedlabels = @searchedlabels + $pivot_labels

    svmbygroup = rdf2svm_with_meta_properties(data + $pivot, [])

    # puts "SVM GROUP AFTER PROCESSING"
    # puts svmbygroup.size
    svmbygroup = svmbygroup[0..(svmbygroup.size - pivot_size - 1 )] if pivot_size > 0
    annotated =[]

    ############## PRINT RESULTS OF MEASURES
    svmbygroup.each{|g| puts "######"
      puts g
    }

    puts "MODEL DONE"
    puts svmbygroup.size
    puts subjects.size
    idx = -1

    puts "OUTPUT"
    puts $output

    $output =  File.open($output, 'a') if $output.class == String
    f=$output
    all_values = []
    maximus=[]
    svmbygroup.each{|svm|
      svm.map!{|x| x[(x.index(":") + 1)..x.size].to_f}
      maximus << svm.max
      all_values = all_values + svm
    }
    mean_maximus=mean(maximus)
    puts "MEAN OF MAXIMUS"
    puts mean_maximus
    all_values = all_values + [1.0] if !all_values.include?(1.0)
    global_mean_deviation = mean_and_standard_deviation(all_values)
    puts "MEAN / DEVIATION"
    puts global_mean_deviation
    outliers_threshold = [ (global_mean_deviation[0]  - global_mean_deviation[1]), global_mean_deviation[1]].max
    # outliers_threshold =  (global_mean_deviation[0]  - global_mean_deviation[1])
    puts "OUTLIER THRESHOLD"
    puts outliers_threshold

    svmbygroup.each{|svm|
      idx=idx+1
      # puts idx

      groupedsubjects = data[idx].map{|s,p,o| s}.uniq
      ########################### Calculates the threshold
      if $topk == 0
        mean_stdev =  mean_and_standard_deviation(svm)

        final_threshold = mean_stdev[0]
        if mean_stdev[1] > 0.1 and svm.max >= mean_maximus
          final_threshold = mean([svm.max,mean_maximus])
        end
        if global_mean_deviation[1] > 0.13
          final_threshold = [final_threshold , outliers_threshold].max
        end

        final_threshold = 0.99 if final_threshold == 1
        final_threshold = final_threshold + 0.01 if outliers_threshold == final_threshold
        final_threshold = mean_and_standard_deviation(svm.map{|v| v if v >=0.1}.compact)[0] if final_threshold < 0.1 and svm.max >= 0.1
      else
        final_threshold = svm.sort{|a,b| b <=> a}[$topk-1]
      end

      puts "FINAL THRESHOLD - " + idx.to_s
      puts final_threshold

      ##################################################
      svm.each_index{|i|
        line = svm[i]
        final_threshold= $rdsthreshold if $rdsthreshold != nil
        if line >= final_threshold
          $selecteds << groupedsubjects[i]
          if $format == "txt"
            f.write(subjects[idx].to_s.gsub(/[<>]/,"") + "=" + groupedsubjects[i].to_s.gsub(/[<>]/,"") + "\n" )

          else
            f.write(subjects[idx].to_s + " <http://www.w3.org/2002/07/owl#sameAs> " + groupedsubjects[i].to_s + ".\n" )
          end
        end
      }

    }

  end

  def mount_adapter(endpoint, method=:post,cache=true)

    adapter=nil
    begin
      adapter = ConnectionPool.add_data_source :type => :sparql, :engine => :virtuoso, :title=> endpoint , :url =>  endpoint, :results => :sparql_xml, :caching => cache , :request_method => method

    rescue Exception => e
      puts e.getMessage()
      return nil
    end
    return adapter
  end

  def putsx(str)
    create_log() if $logger == nil
    if str.instance_of? Array
      str.each{|x|
        $logger.write(x.to_s)
        $logger.write("\n")
      }
    else
      $logger.write(str.to_s)
      $logger.write("\n")
    end
  # $logger.fsync
  end
end