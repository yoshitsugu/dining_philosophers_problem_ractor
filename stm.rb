# frozen_string_literal: true

require 'securerandom'
require 'ractor/tmvar'

NUM_OF_PHILOSOPHERS = 5

class Philosopher
  def initialize(name, left, right)
    @name = name.freeze
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
    Ractor.atomically do
      @left.take
      @right.take
    end
  end

  def put_forks
    Ractor.atomically do
      @right.put(nil)
      @left.put(nil)
    end
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
  Ractor::TMVar.new
end

rs = NUM_OF_PHILOSOPHERS.times.map do |i|
  Ractor.new("philosopher #{i + 1}", forks[i], forks[(i + 1) % NUM_OF_PHILOSOPHERS]) do |n, l, r|
    Philosopher.new(n, l, r).start
  end
end
Ractor.select(*rs)
