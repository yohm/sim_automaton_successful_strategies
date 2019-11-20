require_relative 'union_find'

require 'minitest/autorun'

class UnionFindTest < Minitest::Test

  def test_init
    uf = UnionFind.new(5)
    assert_equal ({0=>[0],1=>[1],2=>[2],3=>[3],4=>[4]}), uf.to_h
    assert_equal [0,1,2,3,4], uf.roots
    5.times {|i| assert_equal i, uf.root(i) }
  end

  def test_merge
    uf = UnionFind.new(5)
    uf.merge(4,2)
    uf.merge(0,3)
    uf.merge(3,1)
    assert_equal ({0=>[0,1,3],2=>[2,4]}), uf.to_h
    assert_equal [0,2], uf.roots
    assert_equal 0, uf.root(3)
    assert_equal 2, uf.root(2)
  end
end

