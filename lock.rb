require 'securerandom'

NUM_OF_PHILOSOPHERS = 5

class Philosopher
  def initialize(name, left, right)
    @name = name
    @left = left
    @right = right
  end

  def eat
    puts "#{@name} eating..."
    sleep SecureRandom.random_number * 5
  end

  def think
    puts "#{@name} thinking..."
    sleep SecureRandom.random_number * 5
  end

  def take_forks
    @left << :lock
    @left.take
    @right << :lock
    @right.take
  end

  def put_forks
    @right << :unlock
    @right.take
    @left << :unlock
    @left.take
  end

  def start
    loop do
      take_forks
      eat
      put_forks
      think
    end
  end
end

forks = NUM_OF_PHILOSOPHERS.times.map do
  # Mutexはshareableではないので、Ractorで包む
  Ractor.new do
    mutex = Mutex.new
    while msg = Ractor.receive
      case msg
      when :lock
        mutex.lock
        Ractor.yield(:ok)
      when :unlock
        mutex.unlock
        Ractor.yield(:ok)
      end
    end
  end
end

rs = NUM_OF_PHILOSOPHERS.times.map do |i|
  Ractor.new("philosopher #{i + 1}", forks[i % NUM_OF_PHILOSOPHERS], forks[(i + 1) % NUM_OF_PHILOSOPHERS]) do |n, l, r|
    Philosopher.new(n, l, r).start
  end
end
Ractor.select(*rs)
