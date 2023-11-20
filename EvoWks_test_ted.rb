require 'matrix'

class EvoWorks
  ENCOUNTERS = 16
  STIMULUS_MAX = 15
  BEHAVIOR_MAX = 9
  BEST_FITNESS = 12 # number of triggers * (Tp+Tn)
  PSP = 0.75
  TRIGGER_VALUES = Array[0, 4, 8, 12]
  TRIGGER = Matrix.column_vector([1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
  TP = 3
  FP = -1
  FN = -2
  TN = 0

  attr_reader :generations

  def initialize(world, simulations, seed)
    srand(seed)
    @best_brain = Matrix.column_vector([0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1])
    @total_generations = 0
    @world = world
    @simulations = simulations
    @generations = []
    run
  end

  def run
    @simulations.times do
      run_simulation
    end
  end

  def average_generations
    raise 'No simulations have been run!' if @simulations < 1

    @total_generations / @simulations
  end

  def output_results
    print "World = #{@world}: "
    @generations.each { |gen| print "#{gen} " }
    puts "Average: #{average_generations}"
  end

  def run_simulation
    gene_brain = setup_gene_brain
    generations = 0
    loop do
      brain = gene_brain.dup
      fitness = Matrix.row_vector([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
      animal_encounters(fitness, brain)
      reproduce(gene_brain, fitness, brain)
      generations += 1
      break if fitness.max >= BEST_FITNESS
    end
    @generations << generations
    @total_generations += generations
  end

  # Setup gene brain with random connections
  def setup_gene_brain
    gene_brain = Matrix.build(10, 16) { 0 }
    (0..BEHAVIOR_MAX).each do |i|
      (0..STIMULUS_MAX).each do |j|
        gene_brain[i, j] = rand(3..24) if rand >= 0.5
      end
    end
    gene_brain
  end

  # Show stimuli to animals ENCOUNTERS times over their lifetime
  def animal_encounters(fitness, brain)
    ENCOUNTERS.times do |encounter|
      if TRIGGER_VALUES.include?(encounter)
        stimulus = TRIGGER
        trigger = 1
      else
        stimulus = Matrix.column_vector([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        (4..15).each { |j| stimulus[j, 0] = 1 if rand < 0.33 }
        trigger = 0
      end
      generate_behavior(stimulus, fitness, brain, trigger)
    end
  end

  # Modifies fitness based on behavior
  def generate_behavior(stimulus, fitness, brain, trigger)
    threshold = 75 #rand(60..80)
    behavior = brain * stimulus
    (0..BEHAVIOR_MAX).each do |i|
      if behavior[i, 0] >= threshold
        fitness[0, i] += trigger.zero? ? FP : TP
        learn(i, stimulus, brain)
      else
        fitness[0, i] += trigger.zero? ? TN : FP
      end
    end
  end

  # If the stimulus is present and the neuron has fired increase the strength of the connection.
  def learn(idx, stimulus, brain)
    return unless @world == 1
    (0..STIMULUS_MAX).each do |j|
      brain[idx, j] += ((24 - brain[idx, j]) * PSP).round if
        stimulus[j, 0].positive? && brain[idx, j].positive?
    end
  end

  # Kills low fitness animal, replaces with high fitness animal, add variation to all
  def reproduce(gene_brain, fitness, brain)
    best_animal = fitness.find_index(fitness.max)[1]
    worst_animal = fitness.find_index(fitness.min)[1]
    (0..STIMULUS_MAX).each do |j|
      @best_brain[j, 0] = gene_brain[best_animal, j]
      gene_brain[worst_animal, j] = @best_brain[j, 0]
    end

    add_variation(gene_brain)
  end

  def add_variation(gene_brain)
    (0..BEHAVIOR_MAX).each do |i|
      j = rand(0..STIMULUS_MAX)
      if gene_brain[i, j].zero?
        gene_brain[i, j] = rand(3..24) if rand < 0.5
        next
      end
      operand = (gene_brain[i, j] * 0.5).round
      if rand < 0.5
        gene_brain[i, j] += operand
      else
        gene_brain[i, j] -= operand
      end
      gene_brain[i, j] = 24 if gene_brain[i, j] > 24
      gene_brain[i, j] = 0 if gene_brain[i, j] < 3
    end
  end
end

def single_run
  puts 'Enter the number of simulations to run: '
  simulation_amount = gets.chomp.to_i
  puts 'Enter the seed: '
  seed = gets.chomp.to_i
  world_zero = EvoWorks.new(0, simulation_amount, seed)
  world_one = EvoWorks.new(1, simulation_amount, seed)
  world_zero.output_results
  world_one.output_results
end

def bulk_run
  simulations = 0
  positive_result = 0
  (1957..1997).each do |seed|
    world_zero = EvoWorks.new(0, 25, seed)
    world_one = EvoWorks.new(1, 25, seed)
    world_zero.output_results
    world_one.output_results
    puts
    simulations += 1
    positive_result += 1 if world_zero.average_generations > world_one.average_generations
  end
  puts "Positive results: #{positive_result} out of #{simulations} simulations."
end

#single_run
bulk_run
