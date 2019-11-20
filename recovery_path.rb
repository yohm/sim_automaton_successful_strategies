require_relative 'n2m2_strategy'
require_relative 'n3m2_strategy'
require_relative 'n3m3_strategy'
require_relative 'graph'

unless ARGV.size == 2
  $stderr.puts "usage: ruby #{__FILE__} [strategy] [init_state]"
  $stderr.puts "Example: ruby recovery_path.rb cddcdddcddcdddcddddddcccddddcccdddcddddd cccdcc"
  $stderr.puts "Example: ruby recovery_path.rb cdcdcdcdddcdddddcccdcdcdddddddddcdcdcdcdddddddddcdcdcdcdddddddddccddcdddcdcdddcddcdddcddddddddddcdddcdddddcdddcddcdddcdddddddddddccddccdcccdccddccdccddcddccddccdccddccdccddccddcddccddcddccddcccdddcddddccdddcddcddccddddddddcdcdcdcdddddcdddcddcdcdcddddddddddcdcdcdcdddddddddcdcdcdcdddddddddcdcdcdcdddddddddcdcdcdcdddddddddcdddcdddddcdddcddccddcddddddddddcdddcdddddcdddcddcdddcdddddddddddccddccdccddccddcddccddcddccddccdccddccdccddccddcddccddcddccddcccdddcdddddcdddcddcdddcddddddddddcdddcdddddcdddcddcdddcdddddddddd cccccdccc"
  raise "invalid number of arguments"
end

DEBUG = true

s = ARGV[0]
if s.length == 16
  $stderr.puts "loading n=2,m=2 strategy:" if DEBUG
  str = N2M2::Strategy.make_from_bits(s)
  init_state = N2M2::State.make_from_bits(ARGV[1])
  players = [:A,:B]
elsif s.length == 40
  $stderr.puts "loading n=3,m=2 strategy:" if DEBUG
  str = N3M2::Strategy.make_from_bits(s)
  init_state = N3M2::State.make_from_bits(ARGV[1])
  players = [:A,:B,:C]
elsif s.length == 512
  $stderr.puts "loading n=3,m=3 strategy:" if DEBUG
  str = N3M3::Strategy.make_from_bits(s)
  init_state = N3M3::State.make_from_bits(ARGV[1])
  players = [:A,:B,:C]
else
  $stderr.puts "unsupported input format"
  raise "invalid argument"
end

$stderr.puts "initial state : #{init_state}" if DEBUG

visited = []
s = init_state
until visited.include?(s)
  visited.push(s)
  s = str.next_state_with_self(s)
end

uf, as_g = str.minimize_DFA
# $stderr.puts uf.tree.inspect if DEBUG

visited.each do |s|
  s_arr = players.map {|x| s.state_from(x) }
  puts s_arr.map(&:to_s).inspect
  puts s_arr.map {|s2| uf.root(s2.to_id) }.inspect
end
