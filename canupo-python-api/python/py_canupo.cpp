/*
py_canupo.cpp: wrap CANUPO libraries into a python interface using
Boost.Python.

Zhan Li <zhanli1986@gmail.com>
 */

#include <iostream>
#include "helpers.hpp"
#include <boost/python.hpp>
// #include <boost/python/module.hpp>
// #include <boost/python/def.hpp>
// #include <boost/python/implicit.hpp>
#include <boost/python/suite/indexing/vector_indexing_suite.hpp>
// #include <boost/foreach.hpp>
#include <boost/shared_ptr.hpp>

namespace bp = boost::python;

// // write a class of integer that can be passed by reference
// struct RefInt
// {
//   RefInt(int val) { m_val=val; }
//   int m_val;
//   void set_value(int val) { m_val=val; }
//   int get_value() { return m_val; }
// };

// // write a wrapper function for read_msc_header, as Python does NOT support passing by reference 
// int py_read_msc_header(MSCFile& mscfile, std::vector<FloatType>& scales, RefInt& nparams)
// {
//   int ptnparams, npts;
//   npts = read_msc_header(mscfile, scales, ptnparams);
//   nparams.set_value(ptnparams);
//   return npts;
// }

bp::tuple py_read_msc_header(MSCFile& mscfile)
{
  int ptnparams, npts;
  std::vector<FloatType> scales;
  npts = read_msc_header(mscfile, scales, ptnparams);

  bp::list py_scales;
  for(std::size_t i=0; i<scales.size(); i++)
  {
    py_scales.append(scales[i]);
  }
  // std::for_each(scales.begin(), scales.end(), py_scales.append);
  return bp::make_tuple(npts, py_scales, ptnparams);
}

void py_read_msc_data(MSCFile& mscfile, int nscales, int npts, std::vector<FloatType>& data, int nparams, bool convert_from_tri_to_2D=false)
{
  data.clear();
  std::size_t ndata = npts*nscales*2;
  data.resize(ndata);
  read_msc_data(mscfile, nscales, npts, data.data(), nparams, convert_from_tri_to_2D);
}
BOOST_PYTHON_FUNCTION_OVERLOADS(py_read_msc_data_overloads, py_read_msc_data, 5, 6);

BOOST_PYTHON_MODULE(canupo)
{
  using namespace boost::python;

  class_<std::vector<FloatType> >("FloatVec")
    .def(vector_indexing_suite<std::vector<FloatType> >())
    ;

  // class_<RefInt>("RefInt", init<int>())
  //   .def_readwrite("value", &RefInt::m_val)
  //   ;
  
  class_<MSCFile>("MSCFile", init<const char*>())
    ;

  def("read_msc_header", py_read_msc_header);
  def("read_msc_data", py_read_msc_data, py_read_msc_data_overloads());
}
