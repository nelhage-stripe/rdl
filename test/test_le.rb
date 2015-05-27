require 'minitest/autorun'
require_relative '../lib/rdl.rb'

class TypeTest < Minitest::Test
  def setup
    @parser = RDL::Type::Parser.new
    @sym_t = RDL::Type::SymbolType.new :t
    @sym_u = RDL::Type::SymbolType.new :u
  end

  def test_le
    t1 = "##Array<:t>"
    t2 = "##Array<t>"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2
    h2 = {}
    r = t1.le(t2, h2)
    h = {:t => @sym_t}
    assert_equal(true, r)
    assert_equal(h, h2)

    t1 = "##Array<Fixnum>"
    t2 = "##Array<t>"
    t3 = "##Fixnum"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2
    t3 = @parser.scan_str t3
    h2 = {}
    r = t1.le(t2, h2)
    h = {:t => t3}
    assert_equal(true, r)
    assert_equal(h, h2)

    t1 = "##Array<Array<Array<Array<Fixnum>>>>"
    t2 = "##Array<t>"
    t3 = "##Array<Array<Array<Fixnum>>>"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2
    t3 = @parser.scan_str t3
    h2 = {}
    r = t1.le(t2, h2)
    h = {:t => t3}
    assert_equal(true, r)
    assert_equal(h, h2)

    t1 = "##Array<Array<Array<Array<Fixnum>>>>"
    t2 = "##Array<Array<t>>"
    t3 = "##Array<Array<Fixnum>>"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2
    t3 = @parser.scan_str t3
    h2 = {}
    r = t1.le(t2, h2)
    h = {:t => t3}
    assert_equal(true, r)
    assert_equal(h, h2)

    t1 = "##Hash<Array<Fixnum>, String>"
    t2 = "##Hash<Array<t>, t>"
    t3 = "##Fixnum or String"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2
    t3 = @parser.scan_str t3
    h2 = {}
    r = t1.le(t2, h2)
    h = {:t => t3}
    assert(true, r)
    assert(h, h2)

    t1 = "##Hash<Array<Fixnum>, String>"
    t2 = "##Hash<t, t>"
    t3 = "##Array<Fixnum> or String"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2
    t3 = @parser.scan_str t3
    h2 = {}
    r = t1.le(t2, h2)
    h = {:t => t3}
    assert_equal(true, r)
    assert_equal(h, h2)

    t1 = "##Hash<Array<Fixnum>,Array<Fixnum>>"
    t2 = "##Hash<t, t>"
    t3 = "##Array<Fixnum>"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2
    t3 = @parser.scan_str t3
    h2 = {}
    r = t1.le(t2, h2)
    h = {:t => t3}
    assert_equal(true, r)
    assert_equal(h, h2)

    t1 = "##Array<String>"
    t2 = "##t"
    t3 = "##Array<Fixnum> or Array<String>"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2
    t3 = @parser.scan_str t3
    r = t1.le(t2, h2)
    h = {:t => t3}
    assert_equal(true, r)
    assert_equal(h, h2)

    t1 = "##Hash<Array<Array<Fixnum>>, Hash<Array<Array<Array<Array<String>>>>>>"
    t2 = "##Hash<Array<Array<t>>, Hash<Array<Array<Array<Array<u>>>>>>"
    t3 = "##Fixnum"
    u3 = "##String"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2
    t3 = @parser.scan_str t3
    u3 = @parser.scan_str u3
    h2 = {}
    r, h = t1.le(t2, h2)
    h = {:t => t3, :u => u3}
    assert_equal(true, r)
    assert_equal(h, h2)
  end

  def test_le_false
    t1 = "##Array<t>"
    t2 = "##Array<t>"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2

    assert_raises RDL::TypeComparisonException do
      t1.le t2
    end

    t1 = "##Array<t>"
    t2 = "##Fixnum"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2

    assert_raises RDL::TypeComparisonException do
      t1.le t2
    end

    t1 = "##Array<t>"
    t2 = "##Array"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2

    assert_raises RDL::TypeComparisonException do
      t1.le t2
    end
  end

  def test_u
    t1 = "##Array<Fixnum or String or TrueClass>"
    t2 = "##Array<t>"
    t3 = "##String or Fixnum or TrueClass"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2
    t3 = @parser.scan_str t3
    h2 = {}
    r = t1.le(t2, h2)
    h = {:t => t3}
    assert_equal(true, r)
    assert_equal(h, h2)

    t1 = "##Array<Fixnum or String or abc>"
    t2 = "##%any"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2

    assert_raises RDL::TypeComparisonException do 
      r, h = t1.le(t2)
    end
  end

  def test_get_vartypes
    t = "##Array<Hash<t, u> or v>"
    t = @parser.scan_str t
    v = t.get_vartypes
    assert_equal([:t, :u, :v].to_set, v.to_set)

    t = "##Array<Fixnum or String or abc>"
    t = @parser.scan_str t
    v = t.get_vartypes
    assert_equal([:abc], v)
  end

  def test_ambiguous
    t1 = "##Fixnum"
    t2 = "##t or u"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2
    
    assert_raises RDL::AmbiguousUnionException do
      t1.le t2
    end

    t1 = "##Array<Fixnum>"
    t2 = "##Array<Fixnum> or u"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2
    
    assert_raises RDL::AmbiguousUnionException do
      t1.le t2
    end
  end

  def test_replace_vartypes
    t1 = "(u) -> Array<u>"
    t2 = "(Fixnum or String) -> Array<Fixnum or String>"
    t3 = "##Fixnum or String"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2
    t3 = @parser.scan_str t3
    h = {:u => t3}
    t4 = t1.replace_vartypes(h)
    assert_equal(t2, t4)

    t1 = "(u) -> Array<u or t>"
    t2 = "(Fixnum or String) -> Array<Fixnum or String or TrueClass>"
    t3 = "##Fixnum or String"
    t4 = "##TrueClass"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2
    t3 = @parser.scan_str t3
    t4 = @parser.scan_str t4
    h = {:u => t3, :t => t4}
    t4 = t1.replace_vartypes(h)
    assert_equal(t2, t4)

    t1 = "(u) {(t) -> u} -> Array<u or t>"
    t2 = "(Fixnum or String) {(TrueClass) -> Fixnum or String} -> Array<Fixnum or String or TrueClass>"
    t3 = "##Fixnum or String"
    t4 = "##TrueClass"
    t1 = @parser.scan_str t1
    t2 = @parser.scan_str t2
    t3 = @parser.scan_str t3
    t4 = @parser.scan_str t4
    h = {:u => t3, :t => t4}
    t4 = t1.replace_vartypes(h)
    assert_equal(t2, t4)
  end

  def test_rdl_type
    t1 = 2.rdl_type
    t2 = RDL::Type::NominalType.new Fixnum
    assert_equal(t2, t1)

    t1 = nil.rdl_type
    t2 = RDL::Type::NilType.new
    assert_equal(t2, t1)

    t1 = :abc.rdl_type
    t2 = RDL::Type::SymbolType.new :abc
    assert_equal(t2, t1)

    t1 = [1, true, 2, "a", :b].rdl_type
    t2 = "##Array<Fixnum or String or :b or TrueClass>"
    t2 = @parser.scan_str t2
    assert_equal(t2, t1)

    t1 = {:a => "A", :b => "B", :c => 123, "d" => true, "e" => false}.rdl_type
    t2 = "##Hash<:a or :b or :c or String, String or Fixnum or %bool>"
    t2 = @parser.scan_str t2
    assert_equal(t2, t1)
  end

  def test_type_checking
    actual_args = [1]
    annotated_type = @parser.scan_str "(Fixnum) -> Fixnum"
    method_types = annotated_type
    stype = RDL::MethodCheck.select_and_check_args(method_types, "A#foo", actual_args)
    assert_equal(annotated_type, stype)

    annotated_type = @parser.scan_str "(Fixnum, ?String) -> Fixnum"
    method_types = annotated_type
    stype = RDL::MethodCheck.select_and_check_args(method_types, "A#foo", actual_args)
    assert_equal(annotated_type, stype)

    actual_args = [1, 2]
    annotated_type = @parser.scan_str "(Fixnum, ?String) -> Fixnum"
    method_types = annotated_type

    assert_raises RDL::TypesigException do
      RDL::MethodCheck.select_and_check_args(method_types, "A#foo", actual_args)
    end

    actual_args = [1, "a"]
    annotated_type = @parser.scan_str "(Fixnum, ?String) -> Fixnum"
    method_types = annotated_type
    stype = RDL::MethodCheck.select_and_check_args(method_types, "A#foo", actual_args)
    assert_equal(annotated_type, stype)

    annotated_type = @parser.scan_str "(Fixnum, *String) -> Fixnum"
    method_types = annotated_type
    stype = RDL::MethodCheck.select_and_check_args(method_types, "A#foo", actual_args)
    assert_equal(annotated_type, stype)

    actual_args = [1, "a", "b", "c"]
    stype = RDL::MethodCheck.select_and_check_args(method_types, "A#foo", actual_args)
    assert_equal(annotated_type, stype)

    actual_args = [1, "a", 2]
    assert_raises RDL::TypesigException do
      stype = RDL::MethodCheck.select_and_check_args(method_types, "A#foo", actual_args)
    end

    annotated_type = @parser.scan_str "(String) -> Fixnum"
    method_types = annotated_type
    
    assert_raises RDL::TypesigException do
      RDL::MethodCheck.select_and_check_args(method_types, "A#foo", actual_args)
    end
    
    actual_args = [1, "a", :b]
    annotated_type = @parser.scan_str "(t, t, t) -> %any"
    method_types = annotated_type
    stype = RDL::MethodCheck.select_and_check_args(method_types, "A#foo", actual_args)
    ut = "(:b or String or Fixnum, :b or String or Fixnum, :b or String or Fixnum) -> %any"
    ut = @parser.scan_str ut
    assert_equal(ut, stype)
    
    actual_args = [1, "a", :b, :c]
    annotated_type = @parser.scan_str "(t, t, u, u) -> %any"
    method_types = annotated_type
    stype = RDL::MethodCheck.select_and_check_args(method_types, "A#foo", actual_args)
    ut = "(String or Fixnum, String or Fixnum, :b or :c, :b or :c) -> %any"
    ut = @parser.scan_str ut
    assert_equal(ut, stype)

    actual_args = [[1], ["a"], :b]
    annotated_type = @parser.scan_str "(Array<t>, Array<t>, :b) -> %any"
    method_types = annotated_type
    stype = RDL::MethodCheck.select_and_check_args(method_types, "A#foo", actual_args)
    ut = "(Array<String or Fixnum>, Array<String or Fixnum>, :b) -> %any"
    ut = @parser.scan_str ut
    assert_equal(ut, stype)

    actual_args = [{:a => 1, "b" => 2}]
    annotated_type = @parser.scan_str "(Hash<k, v>) -> %any"
    method_types = annotated_type
    stype = RDL::MethodCheck.select_and_check_args(method_types, "A#foo", actual_args)
    ut = "(Hash<:a or String, Fixnum>) -> %any"
    ut = @parser.scan_str ut
    assert_equal(ut, stype)

    actual_args = [{:a => 1, "b" => 2}, :abc]
    annotated_type = @parser.scan_str "(Hash<k, v>, ?k) -> %any"
    method_types = annotated_type
    stype = RDL::MethodCheck.select_and_check_args(method_types, "A#foo", actual_args)
    ut = "(Hash<:a or String or :abc, Fixnum>, ?:a or String or :abc) -> %any"
    ut = @parser.scan_str ut
    assert_equal(ut, stype)

    actual_args = [:a, :b, :c, :d]
    annotated_type = @parser.scan_str "(*t) -> %any"
    method_types = annotated_type
    stype = RDL::MethodCheck.select_and_check_args(method_types, "A#foo", actual_args)
    ut = "(*:a or :b or :c or :d) -> %any"
    ut = @parser.scan_str ut
    assert_equal(ut, stype)

    actual_args = [:a, :b, :c, :d]
    annotated_type = @parser.scan_str "(t, *t) -> %any"
    method_types = annotated_type
    stype = RDL::MethodCheck.select_and_check_args(method_types, "A#foo", actual_args)
    ut = "(:a or :b or :c or :d, *:a or :b or :c or :d) -> %any"
    ut = @parser.scan_str ut
    assert_equal(ut, stype)

    actual_args = [:a]
    annotated_type = @parser.scan_str "(%any, %any) -> %any"
    method_types = annotated_type
    assert_raises RDL::TypesigException do
      RDL::MethodCheck.select_and_check_args(method_types, "A#foo", actual_args)
    end
  end
end
