require_relative 'graph'

require 'minitest/autorun'

class TestDirectedGraph < Minitest::Test

  def setup
    @g = DirectedGraph.new(5)
    @g.add_link(1, 0)
    @g.add_link(0, 2)
    @g.add_link(2, 1)
    @g.add_link(0, 3)
    @g.add_link(3, 4)
    @g.add_link(4, 4)
  end

  def test_add_link
    assert_equal 5, @g.n
    expected = {0=>[2,3],1=>[0],2=>[1],3=>[4],4=>[4]}
    assert_equal expected, @g.links
  end

  def test_sccs
    assert_equal [ [0,1,2], [4] ], @g.sccs.map(&:sort).sort
  end

  def test_transient_nodes
    assert_equal [3], @g.transient_nodes
    assert_equal [0,1,2,4], @g.non_transient_nodes.sort
  end

  def test_to_dot
    s = @g.to_dot
    assert_equal s.empty?, false
  end

  def test_dfs
    traversed = []
    @g.dfs(0) {|n| traversed << n }
    assert_equal [0,2,1,3,4], traversed
  end

  def test_accessible
    assert_equal true, @g.is_accessible?(0,4)
    assert_equal false, @g.is_accessible?(3,0)
  end
end

