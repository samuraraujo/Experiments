#Serimi Functionalities.
#Author: Samur Araujo
#Date: 10 April 2011.
#License: SERIMI is distributed under the LGPL[http://www.gnu.org/licenses/lgpl.html] license.
require  File.dirname(__FILE__)+ '/../../../active_rdf/lib/active_rdf'
require  File.dirname(__FILE__)+'/../../../activerdf_sparql-1.3.6/lib/activerdf_sparql/init'
require  File.dirname(__FILE__)+'/datamodel/endpoints.rb'
require 'active_support/inflector'

# require "search_module.rb"
require  File.dirname(__FILE__)+"/solver/serimi_module.rb"
require  File.dirname(__FILE__)+"/solver/serimi_class.rb"
require  File.dirname(__FILE__)+"/solver/class_builder.rb"
require  File.dirname(__FILE__)+'/alignment/attribute-assign.rb'
require  File.dirname(__FILE__)+"/util/logger.rb"
require  File.dirname(__FILE__)+'/datamodel/datasource.rb'
require  File.dirname(__FILE__)+"/datamodel/source.rb"
require  File.dirname(__FILE__)+"/datamodel/target.rb"
require  File.dirname(__FILE__)+"/util/extension_module.rb"
require  File.dirname(__FILE__)+"/util/matching_module.rb"
require  File.dirname(__FILE__)+"/util/feature_counter.rb"

class Initializer
  def initialize(params)
    create_log()
    puts "Parameters:"
    $featurecounter = FeatureCounter.new()
     
     
    params.each { |k,v| puts "#{k} => #{v}" }
     totallimit=nil
    $stopwords=[]
    $textp=[]
    $pivot = []
    # $pivot_labels = []
    $pivot_subjects = []
    $aligner = SerimiAligner.new()
    $usepivot=false
    $topk=params[:topk].to_i
    $output=params[:output] if $output == nil
    $format=params[:format]
    $limit=params[:limit]    
    $cluster=params[:cluster]    
    $filter_threshold=params[:stringthreshold]
    $rdsthreshold=params[:rdsthreshold]
    $aligner=eval(params[:aligner]).new() if params[:aligner] != nil
    $usepivot=true if params[:usepivot] ==  'true'
    $blocking=true  if params[:blocking] ==  'true'
    $transitionupdate=true  if params[:transitionupdate] ==  'true'
    $globalrecall=true  if params[:globalrecall] ==  'true'
    if params[:append] == 'w'
      File.delete($output) if  File.exist?($output)
    end
    klasses =  [params[:class]]
    klasses =  ["<"+ params[:class] + ">"] if  params[:class].index("<") == nil
 
    
    source = Source.new(params)
    
   if $cluster != nil
     klasses =  source.get_clusters($cluster,klasses[0])      
   end
    
    klasses[0..1].each{|klass|
    puts "processing klass"
    puts "Obtaning all instances instances"
    
    $instances = source.set_instances(klass,totallimit)
  
    alignments = []
    
    alignments = $aligner.alignment_algorithm($instances,5)#[0..1]
    puts "Alignments"
    puts alignments
    t1 = Time.now()
  
    solver = Serimi.new()
    $limit = $instances.size if $limit == nil
    puts" $limit"
    puts $limit
    path = HeuristicSearch.new($instances[0..$limit],alignments,solver).search()

    data = path.map{|x| x.candidate.elements}
    # puts "DATA"
    # puts data.each{|x| puts x.size}
    solution = solver.solve(data,path.map{|x| x.instance})
    
    ww "HEURISTIC ELAPSED TIME: " +  (Time.now() - t1).to_s
 } 
   close_log()
  end
  
end
